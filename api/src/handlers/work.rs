use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;
use serde::Serialize;

use crate::models::{ApiResource, Clay, CurrentState, Event, Images, State as WorkState, Work};
use crate::{handle_optional_result, internal_error, AppState};

pub(crate) static WORK_DTO_QUERY: &str = "
SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at, w.header_key, w.thumbnail_key,
e.current_state_id, e.current_state_transitioned,
c.id as clay_id, c.name as clay_name, c.description as clay_description, c.shrinkage as clay_shrinkage
FROM works w
JOIN (
    SELECT work_id, current_state as current_state_id, created_at as current_state_transitioned
    FROM events
    WHERE id IN (
        SELECT MAX(id)
        FROM events
        GROUP BY work_id
    )
) e ON w.id = e.work_id
JOIN clays c ON w.clay_id = c.id";

#[derive(sqlx::FromRow, Serialize)]
pub(crate) struct WorkDTO {
    id: i32,
    project_id: i32,
    name: String,
    notes: Option<String>,
    clay_id: i32,
    clay_name: String,
    clay_description: Option<String>,
    clay_shrinkage: f64,
    current_state_id: i32,
    current_state_transitioned: NaiveDateTime,
    glaze_description: Option<String>,
    header_key: Option<String>,
    thumbnail_key: Option<String>,
    created_at: NaiveDateTime,
}

pub(crate) fn workdto_to_work(workdto: WorkDTO, appstate: &AppState) -> Work {
    let images = Images {
        header: workdto
            .header_key
            .map(|k| format!("{}/{}", appstate.config.images_url, k)),
        thumbnail: workdto
            .thumbnail_key
            .map(|k| format!("{}/{}", appstate.config.images_url, k)),
    };

    let clay = Clay {
        id: workdto.clay_id,
        name: workdto.clay_name,
        description: workdto.clay_description,
        shrinkage: workdto.clay_shrinkage,
    };

    Work {
        id: workdto.id,
        project: (ApiResource::Project, workdto.project_id).into(),
        name: workdto.name,
        notes: workdto.notes,
        clay,
        current_state: CurrentState {
            state: workdto.current_state_id.into(),
            transitioned_at: workdto.current_state_transitioned,
        },
        glaze_description: workdto.glaze_description,
        images,
        created_at: workdto.created_at,
    }
}

pub(crate) async fn works(State(appstate): State<AppState>) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(WORK_DTO_QUERY)
        .fetch_all(&appstate.pool)
        .await
        .map(|works| {
            works
                .into_iter()
                .map(|w| workdto_to_work(w, &appstate))
                .collect::<Vec<Work>>()
        })
        .map(Json)
        .map_err(internal_error)
}

pub(crate) async fn work(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    let result = sqlx::query_as::<_, WorkDTO>(&format!("{} {}", WORK_DTO_QUERY, "WHERE w.id = ?"))
        .bind(id)
        .fetch_optional(&appstate.pool)
        .await
        .map(|work_dto| work_dto.map(|w| workdto_to_work(w, &appstate)));

    handle_optional_result(result)
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
    State(appstate): State<AppState>,
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
    .fetch_all(&appstate.pool)
    .await
    .map(|events| events.into_iter().map(Event::from).collect::<Vec<Event>>())
    .map(Json)
    .map_err(internal_error)
}
