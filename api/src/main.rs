mod handlers;
mod models;

use axum::{http::StatusCode, response::IntoResponse, routing::get, Json, Router};
use serde::Serialize;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePool, SqlitePoolOptions};
use std::error::Error;
use std::net::SocketAddr;

use handlers::event::events;
use handlers::project::{project, projects, works as project_works};
use handlers::work::{events as work_events, work, works};

#[derive(Clone)]
pub struct AppState {
    config: Config,
    pool: SqlitePool,
}

#[derive(Clone)]
pub struct Config {
    images_url: String,
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

    let config = Config {
        images_url: "https://img.wyrhtaceramics.com".to_string(),
    };

    let state = AppState { config, pool };

    let app = Router::new()
        .route("/projects", get(projects))
        .route("/projects/:id", get(project))
        .route("/projects/:id/works", get(project_works))
        .route("/events", get(events))
        .route("/works", get(works))
        .route("/works/:id", get(work))
        .route("/works/:id/events", get(work_events))
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
