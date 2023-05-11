use axum::{http::StatusCode, response::IntoResponse, Json};
use serde::Serialize;
use serde_json::json;
use std::error::Error;
use tracing::{event, Level};

#[derive(Debug)]
pub(crate) enum WyrhtaError {
    InternalServerError,
    ResourceNotFound,
    ImageUploadError,
    InvalidStateTransition,
}

pub(crate) struct OptionalResult<T, E>(pub Result<Option<T>, E>);

impl<T, E> From<Result<Option<T>, E>> for OptionalResult<T, E> {
    fn from(result: Result<Option<T>, E>) -> Self {
        OptionalResult(result)
    }
}

impl IntoResponse for WyrhtaError {
    fn into_response(self) -> axum::response::Response {
        let (status, msg) = match self {
            Self::InternalServerError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "an internal server error has occured",
            ),
            Self::ResourceNotFound => (StatusCode::NOT_FOUND, "resource not found"),
            Self::ImageUploadError => (StatusCode::INTERNAL_SERVER_ERROR, "failed to upload image"),
            Self::InvalidStateTransition => (StatusCode::BAD_REQUEST, "invalid state transition"),
        };
        (status, Json(json!({ "error": msg }))).into_response()
    }
}

pub(crate) fn internal_error<E>(err: E) -> WyrhtaError
where
    E: std::error::Error,
{
    event!(Level::ERROR, error = ?err);
    WyrhtaError::InternalServerError
}

impl<T: Serialize, E: Error> IntoResponse for OptionalResult<T, E> {
    fn into_response(self) -> axum::response::Response {
        match self.0 {
            Ok(Some(value)) => Json(value).into_response(),
            Ok(None) => WyrhtaError::ResourceNotFound.into_response(),
            Err(err) => internal_error(err).into_response(),
        }
    }
}
