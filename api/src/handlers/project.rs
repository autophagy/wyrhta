use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::sqlite::SqlitePool;

use crate::internal_error;

#[derive(sqlx::FromRow, Serialize)]
pub(crate) struct Project {
    id: i32,
    name: String,
    description: String,
    created_at: NaiveDateTime,
}

#[derive(sqlx::FromRow, Serialize)]
pub(crate) struct Work {
    id: i32,
    name: String,
    description: String,
    created_at: NaiveDateTime,
}

pub(crate) async fn projects(State(pool): State<SqlitePool>) -> impl IntoResponse {
    sqlx::query_as::<_, Project>("SELECT id, name, description, created_at FROM projects")
        .fetch_all(&pool)
        .await
        .map(Json)
        .map_err(internal_error)
}

pub(crate) async fn project(
    Path(id): Path<i32>,
    State(pool): State<SqlitePool>,
) -> impl IntoResponse {
    sqlx::query_as::<_, Project>(
        "SELECT id, name, description, created_at FROM projects WHERE id = ?",
    )
    .bind(id)
    .fetch_one(&pool)
    .await
    .map(Json)
    .map_err(internal_error)
}

pub(crate) async fn works(
    Path(id): Path<i32>,
    State(pool): State<SqlitePool>,
) -> impl IntoResponse {
    sqlx::query_as::<_, Work>(
        "SELECT id, name, description, created_at FROM works WHERE project_id = ?",
    )
    .bind(id)
    .fetch_all(&pool)
    .await
    .map(Json)
    .map_err(internal_error)
}
