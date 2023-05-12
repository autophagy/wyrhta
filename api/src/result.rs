use crate::error::Error;
use axum::{response::IntoResponse, Json};
use serde::Serialize;

pub(crate) struct OptionalResult<T>(pub Result<Option<T>, Error>);

impl<T, E> From<Result<Option<T>, E>> for OptionalResult<T>
where
    Error: From<E>,
{
    fn from(result: Result<Option<T>, E>) -> Self {
        OptionalResult(result.map_err(Error::from))
    }
}

impl<T: Serialize> IntoResponse for OptionalResult<T> {
    fn into_response(self) -> axum::response::Response {
        match self.0 {
            Ok(Some(value)) => Json(value).into_response(),
            Ok(None) => Error::ResourceNotFound.into_response(),
            Err(err) => err.into_response(),
        }
    }
}

pub(crate) struct JsonResult<T>(pub Result<T, Error>);

impl<T, E> From<Result<T, E>> for JsonResult<T>
where
    Error: From<E>,
{
    fn from(result: Result<T, E>) -> Self {
        JsonResult(result.map_err(Error::from))
    }
}

impl<T: Serialize> IntoResponse for JsonResult<T> {
    fn into_response(self) -> axum::response::Response {
        self.0.map(Json).into_response()
    }
}

pub(crate) struct EmptyResult(pub Result<(), Error>);

impl<T, E> From<Result<T, E>> for EmptyResult
where
    Error: From<E>,
{
    fn from(result: Result<T, E>) -> Self {
        EmptyResult(result.map(|_| ()).map_err(Error::from))
    }
}

impl IntoResponse for EmptyResult {
    fn into_response(self) -> axum::response::Response {
        self.0.into_response()
    }
}
