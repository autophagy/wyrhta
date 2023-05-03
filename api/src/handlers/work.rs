use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;
use serde::Serialize;

use crate::models::{ApiResource, Clay, CurrentState, Event, Images, State as WorkState, Work};
use crate::{generate_presigned_url, handle_optional_result, internal_error, AppState};

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
    current_state_transitioned: NaiveDateTime,
    glaze_description: Option<String>,
    image_key: Option<String>,
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

        let images = Images {
            header: None,
            thumbnail: None,
        };

        Work {
            id: value.id,
            project: (ApiResource::Project, value.project_id).into(),
            name: value.name,
            notes: value.notes,
            clay,
            current_state: CurrentState {
                state: value.current_state_id.into(),
                transitioned_at: value.current_state_transitioned,
            },
            glaze_description: value.glaze_description,
            images,
            created_at: value.created_at,
        }
    }
}
pub(crate) async fn works(State(appstate): State<AppState>) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(
        "SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at,
        e.current_state_id, e.current_state_transitioned, c.id as clay_id, c.name as clay_name,
        c.description as clay_description, c.shrinkage as clay_shrinkage
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
        JOIN clays c ON w.clay_id = c.id")
        .fetch_all(&appstate.pool)
        .await
        .map(|works| works.into_iter().map(Work::from).collect::<Vec<Work>>())
        .map(Json)
        .map_err(internal_error)
}

async fn workdto_to_work(workdto: WorkDTO, appstate: AppState) -> Work {
    let url = match workdto.image_key {
        None => None,
        Some(key) => {
            let presigned = generate_presigned_url(
                &appstate.s3_client,
                &appstate.config.s3_config.bucket,
                &key,
                appstate.config.s3_config.presign_ttl,
            )
            .await
            .unwrap()
            .to_string();
            Some(presigned)
        }
    };

    let images = Images {
        header: url.clone(),
        thumbnail: url,
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

pub(crate) async fn work(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    let result = sqlx::query_as::<_, WorkDTO>(
        "SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at,
        w.image_key,
        e.current_state_id, e.current_state_transitioned, c.id as clay_id, c.name as clay_name,
        c.description as clay_description, c.shrinkage as clay_shrinkage
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
        JOIN clays c ON w.clay_id = c.id
        WHERE w.id = ?")
        .bind(id)
        .fetch_optional(&appstate.pool)
        .await;

    let result = match result {
        Err(e) => Err(e),
        Ok(None) => Ok(None),
        Ok(Some(workdto)) => {
            let work = workdto_to_work(workdto, appstate).await;
            Ok(Some(work))
        }
    };

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

#[derive(sqlx::FromRow)]
struct ImagesDTO {
    image_key: Option<String>,
}

pub(crate) async fn images(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    let result = sqlx::query_as::<_, ImagesDTO>(
        "SELECT w.image_key
        FROM works w
        WHERE w.id = ?",
    )
    .bind(id)
    .fetch_optional(&appstate.pool)
    .await;

    let result = match result {
        Err(e) => Err(e),
        Ok(None) => Ok(None),
        Ok(Some(images)) => {
            let url = match images.image_key {
                None => None,
                Some(key) => {
                    let presigned = generate_presigned_url(
                        &appstate.s3_client,
                        &appstate.config.s3_config.bucket,
                        &key,
                        appstate.config.s3_config.presign_ttl,
                    )
                    .await
                    .unwrap()
                    .to_string();
                    Some(presigned)
                }
            };
            Ok(Some(Images {
                header: url.clone(),
                thumbnail: url,
            }))
        }
    };

    handle_optional_result(result)
}
