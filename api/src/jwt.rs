use axum::{extract::State, http::Request, middleware::Next, response::IntoResponse};

use axum_extra::extract::cookie::CookieJar;
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Serialize;

use crate::error::Error;
use crate::models::TokenClaims;
use crate::AppState;

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub status: &'static str,
    pub message: String,
}

pub async fn auth<B>(
    cookie_jar: CookieJar,
    State(data): State<AppState>,
    req: Request<B>,
    next: Next<B>,
) -> Result<impl IntoResponse, Error> {
    println!("{:#?}", cookie_jar);
    let token = cookie_jar
        .get("token")
        .map(|cookie| cookie.value().to_string());

    let token = token.ok_or_else(|| Error::NotLoggedIn)?;

    let _claims = decode::<TokenClaims>(
        &token,
        &DecodingKey::from_secret(data.config.jwt_secret.as_ref()),
        &Validation::default(),
    )
    .map_err(|_| Error::InvalidJWT)?
    .claims;

    Ok(next.run(req).await)
}
