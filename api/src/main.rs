mod handlers;
mod models;

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_s3::{config::Region, Client};
use axum::{
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post, put},
    Json, Router,
};
use serde::Serialize;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePool, SqlitePoolOptions};
use std::error::Error;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

use handlers::clay::clays;
use handlers::event::events;
use handlers::image::upload_image_to_s3;
use handlers::project::{post_project, project, projects, put_project, works as project_works};
use handlers::work::{events as work_events, put_state, put_work, work, works};

#[derive(Clone)]
pub struct AppState {
    config: Config,
    pool: SqlitePool,
    s3_client: Client,
}

#[derive(Clone)]
pub struct Config {
    images_url: String,
    images_bucket: String,
}

#[tokio::main]
async fn main() {
    let opts = SqliteConnectOptions::new()
        .filename("db.sl3")
        .journal_mode(SqliteJournalMode::Delete)
        .create_if_missing(true);

    let pool = SqlitePoolOptions::new()
        .max_connections(1)
        .connect_with(opts)
        .await
        .expect("cannot connect to db");

    //    sqlx::migrate!("db/migrations").run(&pool).await.unwrap();

    let region_provider = RegionProviderChain::first_try(Region::new("eu-central-1"));

    let shared_config = aws_config::from_env().region(region_provider).load().await;
    let s3_client = Client::new(&shared_config);

    let config = Config {
        images_url: "https://img.wyrhtaceramics.com".to_string(),
        images_bucket: "img.wyrhtaceramics.com".to_string(),
    };

    let state = AppState {
        config,
        pool,
        s3_client,
    };

    let cors = CorsLayer::permissive();

    let app = Router::new()
        .route("/projects", get(projects).post(post_project))
        .route("/projects/:id", get(project).put(put_project))
        .route("/projects/:id/works", get(project_works))
        .route("/events", get(events))
        .route("/works", get(works))
        .route("/works/:id", get(work).put(put_work))
        .route("/works/:id/events", get(work_events))
        .route("/works/:id/state", put(put_state))
        .route("/clays", get(clays))
        .route("/upload", post(upload_image_to_s3))
        .layer(cors)
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8000));

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

fn internal_error<E>(err: E) -> StatusCode
where
    E: std::error::Error,
{
    println!("{}", err);
    StatusCode::INTERNAL_SERVER_ERROR
}

fn handle_optional_result<T, E>(result: Result<Option<T>, E>) -> impl IntoResponse
where
    T: Serialize,
    E: Error,
{
    match result {
        Ok(Some(value)) => Json(value).into_response(),
        Ok(None) => StatusCode::NOT_FOUND.into_response(),
        Err(err) => internal_error(err).into_response(),
    }
}
