use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::env;

pub type DbPool = Pool<Postgres>;

pub async fn create_pool() -> Result<DbPool, sqlx::Error> {
    let db_url = env::var("POSTGRES_URL")
        .unwrap_or_else(|_| "postgres://postgres:password@localhost:5432/leanpress".to_string());
    PgPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
}
