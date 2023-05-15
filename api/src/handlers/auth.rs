use argon2::{Argon2, PasswordHash, PasswordVerifier};
use axum::{
    extract::State,
    http::{header, Response},
    response::IntoResponse,
    Json,
};
use axum_extra::extract::cookie::{Cookie, SameSite};
use jsonwebtoken::{encode, EncodingKey, Header};

use crate::error::Error;
use crate::models::{LoginUser, TokenClaims};
use crate::result::EmptyResult;
use crate::AppState;

pub(crate) async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginUser>,
) -> Result<impl IntoResponse, Error> {
    let is_valid = match PasswordHash::new(&state.config.password) {
        Ok(parsed_hash) => Argon2::default()
            .verify_password(body.password.as_bytes(), &parsed_hash)
            .map_or(false, |_| true),
        Err(_) => false,
    };

    if !is_valid {
        return Err(Error::InvalidPassword);
    }

    let now = chrono::Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + chrono::Duration::minutes(60)).timestamp() as usize;
    let claims: TokenClaims = TokenClaims { exp, iat };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.config.jwt_secret.as_ref()),
    )
    .unwrap();

    let cookie = Cookie::build("token", token)
        .path("/")
        .max_age(time::Duration::hours(1))
        .same_site(SameSite::Strict)
        .http_only(true)
        .finish();

    let mut response = Response::new("".to_string());
    response
        .headers_mut()
        .insert(header::SET_COOKIE, cookie.to_string().parse().unwrap());
    Ok(response)
}

pub(crate) async fn auth() -> EmptyResult {
    EmptyResult(Ok(()))
}
