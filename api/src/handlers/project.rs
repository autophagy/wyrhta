use axum::extract::{Json as ExtractJson, Path, State};
use chrono::NaiveDateTime;

use crate::handlers::work::{workdto_to_work, WorkDTO, WORK_DTO_QUERY};
use crate::models::{Images, Project, PutProject, Work};
use crate::result::{EmptyResult, JsonResult, OptionalResult};
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

fn projectdto_to_project(projectdto: ProjectDTO, _appstate: &AppState) -> Project {
    let images = Images {
        header: projectdto.header_key,
        thumbnail: projectdto.thumbnail_key,
    };

    Project {
        id: projectdto.id,
        name: projectdto.name,
        description: projectdto.description,
        images,
        created_at: projectdto.created_at,
    }
}

pub(crate) async fn projects(State(appstate): State<AppState>) -> JsonResult<Vec<Project>> {
    sqlx::query_as::<_, ProjectDTO>(PROJECT_DTO_QUERY)
        .fetch_all(&appstate.pool)
        .await
        .map(|projects| {
            projects
                .into_iter()
                .map(|p| projectdto_to_project(p, &appstate))
                .collect::<Vec<Project>>()
        })
        .into()
}

pub(crate) async fn project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> OptionalResult<Project> {
    sqlx::query_as::<_, ProjectDTO>(&format!("{} {}", PROJECT_DTO_QUERY, "WHERE id = ?"))
        .bind(id)
        .fetch_optional(&appstate.pool)
        .await
        .map(|opt_project| opt_project.map(|p| projectdto_to_project(p, &appstate)))
        .into()
}

pub(crate) async fn put_project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
    ExtractJson(data): ExtractJson<PutProject>,
) -> EmptyResult {
    sqlx::query("UPDATE projects SET name=?, description=?, thumbnail_key=? WHERE id=?")
        .bind(data.name)
        .bind(data.description)
        .bind(data.thumbnail)
        .bind(id)
        .execute(&appstate.pool)
        .await
        .into()
}

pub(crate) async fn post_project(
    State(appstate): State<AppState>,
    ExtractJson(data): ExtractJson<PutProject>,
) -> JsonResult<i32> {
    sqlx::query_scalar(
        "INSERT INTO projects (name, description, thumbnail_key)
        VALUES (?, ?, ?)
        RETURNING id",
    )
    .bind(data.name)
    .bind(data.description)
    .bind(data.thumbnail)
    .fetch_one(&appstate.pool)
    .await
    .into()
}

pub(crate) async fn works(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> JsonResult<Vec<Work>> {
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
        .into()
}

// DELETE

pub(crate) async fn delete_project(
    Path(id): Path<i32>,
    State(appstate): State<AppState>,
) -> EmptyResult {
    sqlx::query("DELETE FROM projects WHERE id = ?")
        .bind(id)
        .execute(&appstate.pool)
        .await
        .into()
}
