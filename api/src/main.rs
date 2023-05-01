mod handlers;
mod models;

use axum::{http::StatusCode, response::IntoResponse, routing::get, Json, Router};
use serde::Serialize;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePool, SqlitePoolOptions};
use std::error::Error;
use std::net::SocketAddr;

use handlers::event::events;
use handlers::project::{project, projects, works as project_works};
use handlers::work::{events as work_events, images, work, works};

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_s3::presigning::PresigningConfig;
use aws_sdk_s3::{config::Region, Client};
use std::time::Duration;

#[derive(Clone)]
pub struct AppState {
    config: Config,
    pool: SqlitePool,
    s3_client: Client,
}

#[derive(Clone)]
pub struct S3Config {
    bucket: String,
    presign_ttl: u64,
}

#[derive(Clone)]
pub struct Config {
    s3_config: S3Config,
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

    sqlx::migrate!("db/migrations").run(&pool).await.unwrap();

    let region_provider = RegionProviderChain::first_try(Region::new("eu-central-1"));

    let shared_config = aws_config::from_env().region(region_provider).load().await;
    let s3_client = Client::new(&shared_config);

    let config = Config {
        s3_config: S3Config {
            bucket: "wyrhta-ceramics".to_string(),
            presign_ttl: 5 * 60,
        },
    };

    let state = AppState {
        config,
        pool,
        s3_client,
    };

    let app = Router::new()
        .route("/projects", get(projects))
        .route("/projects/:id", get(project))
        .route("/projects/:id/works", get(project_works))
        .route("/events", get(events))
        .route("/works", get(works))
        .route("/works/:id", get(work))
        .route("/works/:id/events", get(work_events))
        .route("/works/:id/images", get(images))
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

async fn generate_presigned_url(
    client: &Client,
    bucket: &str,
    key: &str,
    expires_in: u64,
) -> Result<http::Uri, Box<dyn Error>> {
    let expires_in = Duration::from_secs(expires_in);
    let presigned_request = client
        .get_object()
        .bucket(bucket)
        .key(key)
        .presigned(PresigningConfig::expires_in(expires_in)?)
        .await?;
    Ok(presigned_request.uri().clone())
}
