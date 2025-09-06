#!/usr/bin/env bash
set -euo pipefail

echo "▶ Post-create: Setting up development environment"

# Source Rust environment
source ~/.cargo/env

# Wait for services to be fully ready
echo "⏳ Waiting for services to start..."
sleep 10

# Wait for Postgres
timeout=60
while ! nc -z postgres 5432 && [ $timeout -gt 0 ]; do
  echo "Waiting for postgres... ($timeout seconds left)"
  sleep 2
  timeout=$((timeout-2))
done

# Wait for MySQL
timeout=60
while ! nc -z mysql 3306 && [ $timeout -gt 0 ]; do
  echo "Waiting for mysql... ($timeout seconds left)"
  sleep 2
  timeout=$((timeout-2))
done

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd panel/frontend
npm install
cd ../..

# Run database migrations
echo "🗄️ Running database migrations..."
export DATABASE_URL="postgres://panel:panel@postgres:5432/panel"

# Create panel database if it doesn't exist
psql "postgres://panel:panel@postgres:5432/postgres" -v ON_ERROR_STOP=1 <<'SQL'
SELECT 'CREATE DATABASE panel' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'panel')\gexec
SQL

# Run migrations
cd panel
if ! command -v sqlx &> /dev/null; then
  echo "Installing sqlx-cli..."
  cargo install sqlx-cli --no-default-features --features postgres
fi
sqlx migrate run --database-url "postgres://panel:panel@postgres:5432/panel" || echo "⚠️ Migrations failed, proceeding..."

# Fallback: ensure users table exists
psql "postgres://panel:panel@postgres:5432/panel" -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SQL

cd ..

# Create MySQL user/db for WordPress
echo "🗄️ Setting up WordPress database..."
mysql -h mysql -uroot -proot <<'SQL'
CREATE USER IF NOT EXISTS 'wp'@'%' IDENTIFIED BY 'wp';
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp'@'%';
FLUSH PRIVILEGES;
SQL

# Build Rust workspace
echo "🦀 Building Rust workspace..."
cargo build

echo "✅ Setup complete!"
echo ""
echo "🚀 You can now run:"
echo "  - Panel backend: cargo run -p panel"
echo "  - Mirror service: cargo run -p mirror"
echo "  - Frontend: cd panel/frontend && npm run dev"
echo ""
echo "🌐 Access points:"
echo "  - Origin WP: http://localhost:8080"
echo "  - Mirror (dev): http://localhost:8001"
echo "  - Panel UI: http://localhost:5173"
