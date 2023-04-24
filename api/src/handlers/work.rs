use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::sqlite::SqlitePool;

use crate::internal_error;
use crate::models::{ApiResource, Clay, Event, State as WorkState, Work};

#[derive(sqlx::FromRow, Serialize)]
struct WorkDTO {
    id: i32,
    project_id: i32,
    name: String,
    notes: Option<String>,
    clay_id: i32,
    clay_name: String,
    clay_description: Option<String>,
    clay_shrinkage: f64,
    current_state_id: i32,
    glaze_description: Option<String>,
    created_at: NaiveDateTime,
}

impl From<WorkDTO> for Work {
    fn from(value: WorkDTO) -> Self {
        let clay = Clay {
            id: value.clay_id,
            name: value.clay_name,
            description: value.clay_description,
            shrinkage: value.clay_shrinkage,
        };

        Work {
            id: value.id,
            project: (ApiResource::Project, value.project_id).into(),
            name: value.name,
            notes: value.notes,
            clay,
            current_state: value.current_state_id.into(),
            glaze_description: value.glaze_description,
            created_at: value.created_at,
        }
    }
}
pub(crate) async fn works(State(pool): State<SqlitePool>) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(
        "SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at,
        e.current_state_id, c.id as clay_id, c.name as clay_name, c.description as clay_description, c.shrinkage as clay_shrinkage
        FROM works w
        JOIN (
            SELECT work_id, current_state as current_state_id
            FROM events
            WHERE id IN (
                SELECT MAX(id)
                FROM events
                GROUP BY work_id
            )
        ) e ON w.id = e.work_id
        JOIN clays c ON w.clay_id = c.id")
        .fetch_all(&pool)
        .await
        .map(|works| works.into_iter().map(Work::from).collect::<Vec<Work>>())
        .map(Json)
        .map_err(internal_error)
}

pub(crate) async fn work(Path(id): Path<i32>, State(pool): State<SqlitePool>) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(
        "SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at,
        e.current_state_id, c.id as clay_id, c.name as clay_name, c.description as clay_description, c.shrinkage as clay_shrinkage
        FROM works w
        JOIN (
            SELECT work_id, current_state as current_state_id
            FROM events
            WHERE id IN (
                SELECT MAX(id)
                FROM events
                GROUP BY work_id
            )
        ) e ON w.id = e.work_id
        JOIN clays c ON w.clay_id = c.id
        WHERE w.id = ?")
        .bind(id)
        .fetch_one(&pool)
        .await
        .map(Work::from)
        .map(Json)
        .map_err(internal_error)
}

#[derive(sqlx::FromRow)]
struct EventDTO {
    id: i32,
    work_id: i32,
    previous_state_id: Option<i32>,
    current_state_id: i32,
    created_at: NaiveDateTime,
}

impl From<EventDTO> for Event {
    fn from(event: EventDTO) -> Self {
        Event {
            id: event.id,
            work: (ApiResource::Work, event.work_id).into(),
            previous_state: event.previous_state_id.map(WorkState::from),
            current_state: event.current_state_id.into(),
            created_at: event.created_at,
        }
    }
}

pub(crate) async fn events(
    Path(id): Path<i32>,
    State(pool): State<SqlitePool>,
) -> impl IntoResponse {
    sqlx::query_as::<_, EventDTO>(
        "SELECT e.id, e.work_id, s1.id AS previous_state_id,
        s2.id AS current_state_id, e.created_at
        FROM events e
        LEFT JOIN states s1 ON e.previous_state = s1.id
        LEFT JOIN states s2 ON e.current_state = s2.id
        WHERE e.work_id = ?",
    )
    .bind(id)
    .fetch_all(&pool)
    .await
    .map(|events| events.into_iter().map(Event::from).collect::<Vec<Event>>())
    .map(Json)
    .map_err(internal_error)
}
