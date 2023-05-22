use axum::extract::{multipart::Field, Multipart, State};
use std::path::Path as FilePath;
use uuid::Uuid;

use crate::error::Error;
use crate::result::JsonResult;
use crate::AppState;

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
) -> JsonResult<String> {
    let file = files.next_field().await.unwrap().unwrap();
    match calculate_s3_key(&file) {
        Some((key, content_type)) => {
            let data = file.bytes().await.unwrap();

            appstate
                .s3_client
                .put_object()
                .bucket(&appstate.config.s3.images_bucket)
                .key(&key)
                .body(data.into())
                .content_type(&content_type)
                .send()
                .await
                .map_err(aws_sdk_s3::Error::from)
                .map(|_| format!("{}/{}", &appstate.config.s3.images_url, &key))
                .into()
        }
        None => Err(Error::ImageUpload).into(),
    }
}
