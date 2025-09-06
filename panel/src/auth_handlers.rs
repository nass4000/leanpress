use crate::models::User;
use actix_web::{web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use serde_json;
use sqlx::{types::uuid::Uuid, Row};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

pub async fn register(
    req: web::Json<RegisterRequest>,
    pool: web::Data<crate::database::DbPool>,
) -> impl Responder {
    let hashed_password = match hash(&req.password, DEFAULT_COST) {
        Ok(h) => h,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    let result = sqlx::query(
        "INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING user_id",
    )
    .bind(&req.email)
    .bind(&hashed_password)
    .fetch_one(pool.get_ref())
    .await;

    match result {
        Ok(row) => match row.try_get::<Uuid, _>("user_id") {
            Ok(user_id) => HttpResponse::Created().json(serde_json::json!({
                "message": "User created successfully",
                "user_id": user_id.to_string()
            })),
            Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create user"
            })),
        },
        Err(sqlx::Error::Database(db_err)) if db_err.is_unique_violation() => {
            HttpResponse::Conflict().json(serde_json::json!({
                "error": "User with this email already exists"
            }))
        }
        Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to create user"
        })),
    }
}

// This should be loaded from environment variables in a real app
const JWT_SECRET: &[u8] = b"your-super-secret-key";

#[derive(Serialize)]
struct Claims {
    sub: String, // Subject (user_id)
    exp: usize,  // Expiration time
}

#[derive(Serialize)]
struct LoginResponse {
    token: String,
}

pub async fn login(
    req: web::Json<LoginRequest>,
    pool: web::Data<crate::database::DbPool>,
) -> impl Responder {
    let user = match sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1")
        .bind(&req.email)
        .fetch_optional(pool.get_ref())
        .await
    {
        Ok(Some(user)) => user,
        Ok(None) => return HttpResponse::Unauthorized().json(serde_json::json!({"error": "Invalid credentials"})),
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    let valid_password = match verify(&req.password, &user.password_hash) {
        Ok(valid) => valid,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    if !valid_password {
        return HttpResponse::Unauthorized().json(serde_json::json!({"error": "Invalid credentials"}));
    }

    // Set expiration to 24 hours from now
    let exp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards")
        .as_secs()
        + 24 * 60 * 60;

    let claims = Claims {
        sub: user.user_id.to_string(),
        exp: exp as usize,
    };

    let token = match encode(&Header::default(), &claims, &EncodingKey::from_secret(JWT_SECRET)) {
        Ok(t) => t,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    HttpResponse::Ok().json(LoginResponse { token })
}
