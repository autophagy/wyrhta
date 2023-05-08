use std::error::Error;
use std::fmt;

use axum::extract::{multipart::Field, Multipart, State};
use axum::response::IntoResponse;
use std::path::Path as FilePath;
use uuid::Uuid;

use crate::{internal_error, AppState};

#[derive(Debug)]
struct ImageUploadError {
    details: String,
}

impl ImageUploadError {
    fn new(msg: &str) -> ImageUploadError {
        ImageUploadError {
            details: msg.to_string(),
        }
    }
}

impl fmt::Display for ImageUploadError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.details)
    }
}

impl Error for ImageUploadError {}

fn calculate_s3_key(file: &Field) -> Option<(String, String)> {
    let category = file.name()?.to_string();
    let extension = FilePath::new(file.file_name()?).extension()?.to_str()?;
    let content_type = file.content_type()?.to_string();
    let id = Uuid::new_v4();

    Some((format!("{}/{}.{}", category, id, extension), content_type))
}

pub(crate) async fn upload_image_to_s3(
    State(appstate): State<AppState>,
    mut files: Multipart,
) -> impl IntoResponse {
    let file = files.next_field().await.unwrap().unwrap();
    let result = match calculate_s3_key(&file) {
        Some((key, content_type)) => {
            let data = file.bytes().await.unwrap();

            let _resp = appstate
                .s3_client
                .put_object()
                .bucket(&appstate.config.images_bucket)
                .key(&key)
                .body(data.into())
                .content_type(&content_type)
                .send()
                .await;

            Ok(format!("{}/{}", &appstate.config.images_url, &key))
        }
        None => Err(ImageUploadError::new("Unable to create key")),
    };
    result.map_err(internal_error)
}
