use serde::Deserialize;
use std::fs::read_to_string;
use std::path::Path;

#[derive(Clone, Deserialize)]
pub struct S3Config {
    pub images_url: String,
    pub images_bucket: String,
}

#[derive(Clone, Deserialize)]
pub struct AuthConfig {
    pub hash: String,
    pub jwt_secret: String,
}

#[derive(Clone, Deserialize)]
pub struct Config {
    pub s3: S3Config,
    pub auth: AuthConfig,
    pub db: String,
}

impl Config {
    pub fn from_path(path: &Path) -> Config {
        let data = read_to_string(path).expect("Unable to read config file");
        serde_json::from_str(&data).expect("Unable to parse JSON file")
    }
}
