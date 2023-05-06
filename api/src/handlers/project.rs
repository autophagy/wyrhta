use axum::response::IntoResponse;
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::NaiveDateTime;

use crate::handlers::work::{workdto_to_work, WorkDTO, WORK_DTO_QUERY};
use crate::models::{Project, Work};
use crate::{handle_optional_result, internal_error, AppState};

static PROJECT_DTO_QUERY: &str = "
SELECT id, name, description, created_at
FROM projects
";

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
    sqlx::query_as::<_, ProjectDTO>(PROJECT_DTO_QUERY)
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
        sqlx::query_as::<_, ProjectDTO>(&format!("{} {}", PROJECT_DTO_QUERY, "WHERE id = ?"))
            .bind(id)
            .fetch_optional(&appstate.pool)
            .await
            .map(|opt_project| opt_project.map(Project::from)),
    )
}

pub(crate) async fn works(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    sqlx::query_as::<_, WorkDTO>(&format!("{} {}", WORK_DTO_QUERY, "WHERE w.project_id = ?"))
        .bind(id)
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
