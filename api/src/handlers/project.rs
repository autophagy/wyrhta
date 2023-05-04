use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;
use serde::Serialize;

use crate::models::{ApiResource, Clay, CurrentState, Images, Project, Work};
use crate::{handle_optional_result, internal_error, AppState};

#[derive(sqlx::FromRow)]
struct ProjectDTO {
    id: i32,
    name: String,
    description: Option<String>,
    created_at: NaiveDateTime,
}

impl From<ProjectDTO> for Project {
    fn from(value: ProjectDTO) -> Self {
        Project {
            id: value.id,
            name: value.name,
            description: value.description,
            created_at: value.created_at,
        }
    }
}

pub(crate) async fn projects(State(appstate): State<AppState>) -> impl IntoResponse {
    sqlx::query_as::<_, ProjectDTO>("SELECT id, name, description, created_at FROM projects")
        .fetch_all(&appstate.pool)
        .await
        .map(|projects| {
            projects
                .into_iter()
                .map(Project::from)
                .collect::<Vec<Project>>()
        })
        .map(Json)
        .map_err(internal_error)
}

pub(crate) async fn project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    handle_optional_result(
        sqlx::query_as::<_, ProjectDTO>(
            "SELECT id, name, description, created_at FROM projects WHERE id = ?",
        )
        .bind(id)
        .fetch_optional(&appstate.pool)
        .await
        .map(|opt_project| opt_project.map(Project::from)),
    )
}

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

fn workdto_to_work(workdto: WorkDTO, appstate: &AppState) -> Work {
    let url = match workdto.image_key {
        None => None,
        Some(key) => Some(format!("{}/{}", appstate.config.images_url, key)),
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

pub(crate) async fn works(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(
        "SELECT w.id, w.project_id, w.name, w.notes, w.glaze_description, w.created_at, w.image_key,
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
        WHERE w.project_id = ?
        ORDER BY w.id")
        .bind(id)
        .fetch_all(&appstate.pool)
        .await
        .map(|works| works.into_iter().map(|w| workdto_to_work(w, &appstate)).collect::<Vec<Work>>())
        .map(Json)
        .map_err(internal_error)
}
