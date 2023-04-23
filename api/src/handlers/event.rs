use axum::response::IntoResponse;
use axum::{extract::State, Json};
use chrono::NaiveDateTime;
use serde::Serialize;
use sqlx::sqlite::SqlitePool;

use crate::internal_error;

#[derive(sqlx::FromRow)]
struct SQLEvent {
    id: i32,
    work_id: i32,
    work_name: String,
    previous_state: String,
    current_state: String,
    created_at: NaiveDateTime,
}

#[derive(Serialize)]
pub(crate) struct Work {
    id: i32,
    name: String,
}

#[derive(Serialize)]
pub(crate) struct Event {
    id: i32,
    work: Work,
    previous_state: String,
    current_state: String,
    created_at: NaiveDateTime,
}

impl From<SQLEvent> for Event {
    fn from(event: SQLEvent) -> Self {
        let work = Work {
            id: event.work_id,
            name: event.work_name,
        };

        Event {
            id: event.id,
            work,
            created_at: event.created_at,
            previous_state: event.previous_state,
            current_state: event.current_state,
        }
    }
}

pub(crate) async fn events(State(pool): State<SqlitePool>) -> impl IntoResponse {
    sqlx::query_as::<_, SQLEvent>(
        "SELECT e.id, e.work_id, w.name as work_name, s1.name AS previous_state
        s2.name AS current_state, e.created_at
        FROM events e
        LEFT JOIN states s1 ON e.previous_state = s1.id
        LEFT JOIN states s2 ON e.current_state = s2.id
        JOIN works w ON e.work_id = w.id",
    )
    .fetch_all(&pool)
    .await
    .map(|events| events.into_iter().map(Event::from).collect::<Vec<Event>>())
    .map(Json)
    .map_err(internal_error)
}
