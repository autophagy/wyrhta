use axum::response::IntoResponse;
use axum::{
    extract::{Json as ExtractJson, Path, State},
    Json,
};
use chrono::NaiveDateTime;

use crate::error::{internal_error, optional_result};
use crate::handlers::work::{workdto_to_work, WorkDTO, WORK_DTO_QUERY};
use crate::models::{Images, Project, PutProject, Work};
use crate::AppState;

static PROJECT_DTO_QUERY: &str = "
SELECT id, name, description, created_at, header_key, thumbnail_key
FROM projects
";

#[derive(sqlx::FromRow)]
struct ProjectDTO {
    id: i32,
    name: String,
    description: Option<String>,
    header_key: Option<String>,
    thumbnail_key: Option<String>,
    created_at: NaiveDateTime,
}

fn projectdto_to_project(projectdto: ProjectDTO, appstate: &AppState) -> Project {
    let images = Images {
        header: projectdto
            .header_key
            .map(|k| format!("{}/{}", appstate.config.images_url, k)),
        thumbnail: projectdto
            .thumbnail_key
            .map(|k| format!("{}/{}", appstate.config.images_url, k)),
    };

    Project {
        id: projectdto.id,
        name: projectdto.name,
        description: projectdto.description,
        images,
        created_at: projectdto.created_at,
    }
}

pub(crate) async fn projects(State(appstate): State<AppState>) -> impl IntoResponse {
    sqlx::query_as::<_, ProjectDTO>(PROJECT_DTO_QUERY)
        .fetch_all(&appstate.pool)
        .await
        .map(|projects| {
            projects
                .into_iter()
                .map(|p| projectdto_to_project(p, &appstate))
                .collect::<Vec<Project>>()
        })
        .map(Json)
        .map_err(internal_error)
}

pub(crate) async fn project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    optional_result(
        sqlx::query_as::<_, ProjectDTO>(&format!("{} {}", PROJECT_DTO_QUERY, "WHERE id = ?"))
            .bind(id)
            .fetch_optional(&appstate.pool)
            .await
            .map(|opt_project| opt_project.map(|p| projectdto_to_project(p, &appstate))),
    )
}

pub(crate) async fn put_project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
    ExtractJson(data): ExtractJson<PutProject>,
) -> impl IntoResponse {
    let thumbnail_key = data.thumbnail.as_ref().map(|key| {
        key.strip_prefix(&format!("{}/", &appstate.config.images_url))
            .unwrap_or(key)
            .to_owned()
    });

    sqlx::query("UPDATE projects SET name=?, description=?, thumbnail_key=? WHERE id=?")
        .bind(data.name)
        .bind(data.description)
        .bind(thumbnail_key)
        .bind(id)
        .execute(&appstate.pool)
        .await
        .map(|_| ())
        .map_err(internal_error)
}

pub(crate) async fn post_project(
    State(appstate): State<AppState>,
    ExtractJson(data): ExtractJson<PutProject>,
) -> impl IntoResponse {
    let thumbnail_key = data.thumbnail.as_ref().map(|key| {
        key.strip_prefix(&format!("{}/", &appstate.config.images_url))
            .unwrap_or(key)
            .to_owned()
    });

    sqlx::query(
        "INSERT INTO projects (name, description, thumbnail_key)
        VALUES (?, ?, ?)",
    )
    .bind(data.name)
    .bind(data.description)
    .bind(thumbnail_key)
    .execute(&appstate.pool)
    .await
    .map(|_| ())
    .map_err(internal_error)
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

// DELETE

pub(crate) async fn delete_project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> impl IntoResponse {
    sqlx::query("DELETE FROM projects WHERE id = ?")
        .bind(id)
        .execute(&appstate.pool)
        .await
        .map(|_| ())
        .map_err(internal_error)
}
