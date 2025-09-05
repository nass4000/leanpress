use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use dotenv::dotenv;

mod auth_handlers;
mod database;
mod models;

#[get("/health")]
async fn health_check() -> impl Responder {
    HttpResponse::Ok().body("OK")
}

fn config_auth(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/auth")
            .route("/register", web::post().to(auth_handlers::register))
            .route("/login", web::post().to(auth_handlers::login)),
    );
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();

    let pool = database::create_pool().await.expect("Failed to create database pool.");

    println!("🚀 Server started successfully at http://0.0.0.0:8000");

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .configure(config_auth)
            .service(health_check)
    })
    .bind(("0.0.0.0", 8000))?
    .run()
    .await
}
