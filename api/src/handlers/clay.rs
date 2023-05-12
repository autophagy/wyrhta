use axum::extract::State;

use crate::models::Clay;
use crate::result::JsonResult;
use crate::AppState;

#[derive(sqlx::FromRow)]
struct ClayDTO {
    id: i32,
    name: String,
    description: Option<String>,
    shrinkage: f64,
}

impl From<ClayDTO> for Clay {
    fn from(clay: ClayDTO) -> Self {
        Clay {
            id: clay.id,
            name: clay.name,
            description: clay.description,
            shrinkage: clay.shrinkage,
        }
    }
}

pub(crate) async fn clays(State(appstate): State<AppState>) -> JsonResult<Vec<Clay>> {
    sqlx::query_as::<_, ClayDTO>(
        "SELECT id, name, description, shrinkage
        FROM clays",
    )
    .fetch_all(&appstate.pool)
    .await
    .map(|clays| clays.into_iter().map(Clay::from).collect::<Vec<Clay>>())
    .into()
}
