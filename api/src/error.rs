use aws_sdk_s3::Error as S3Error;
use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;
use tracing::{event, Level};

#[derive(Debug)]
pub(crate) enum Error {
    InternalServer,
    ResourceNotFound,
    ImageUpload,
    InvalidStateTransition,
    Sqlx(sqlx::Error),
    S3(S3Error),
    InvalidPassword,
    NotLoggedIn,
    InvalidJWT,
}

impl From<sqlx::Error> for Error {
    fn from(e: sqlx::Error) -> Self {
        Error::Sqlx(e)
    }
}

impl From<S3Error> for Error {
    fn from(e: S3Error) -> Self {
        Error::S3(e)
    }
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        let internal_error = (
            StatusCode::INTERNAL_SERVER_ERROR,
            "an internal server error has occured",
        );
        let (status, msg) = match self {
            Self::InternalServer => internal_error,
            Self::ResourceNotFound => (StatusCode::NOT_FOUND, "resource not found"),
            Self::ImageUpload => (StatusCode::INTERNAL_SERVER_ERROR, "failed to upload image"),
            Self::InvalidStateTransition => (StatusCode::BAD_REQUEST, "invalid state transition"),
            Self::Sqlx(e) => {
                event!(Level::ERROR, source = "Sqlx", err = ?e);
                internal_error
            }
            Self::S3(e) => {
                event!(Level::ERROR, source = "S3", err = ?e);
                internal_error
            }
            Self::InvalidPassword => {
                event!(Level::WARN, source = "Authentication: Invalid password");
                (StatusCode::BAD_REQUEST, "invalid password")
            }
            Self::NotLoggedIn => {
                event!(
                    Level::WARN,
                    source = "Authentication: Request made while not logged in"
                );
                (StatusCode::UNAUTHORIZED, "yous are not logged in mate")
            }
            Self::InvalidJWT => {
                event!(Level::WARN, source = "Authentication: Invalid JWT token");
                (StatusCode::UNAUTHORIZED, "invalid token")
            }
        };
        (status, Json(json!({ "error": msg }))).into_response()
    }
}

pub(crate) fn internal_error<E>(err: E) -> Error
where
    E: std::error::Error,
{
    event!(Level::ERROR, error = ?err);
    Error::InternalServer
}
