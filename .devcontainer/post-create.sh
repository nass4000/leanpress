#!/usr/bin/env bash
set -euo pipefail

echo "▶ Post-create: initializing databases and WP defaults"

# Wait for DBs
until nc -z postgres 5432; do echo "⏳ waiting for postgres..."; sleep 1; done
until nc -z mysql 3306; do echo "⏳ waiting for mysql..."; sleep 1; done

# Init Postgres (panel DB)
psql "postgres://panel:panel@postgres:5432/postgres" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'panel') THEN
    PERFORM dblink_exec('dbname=postgres user=panel password=panel', 'CREATE DATABASE panel');
  END IF;
EXCEPTION WHEN undefined_function THEN
  -- dblink may not be available; fallback:
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'panel') THEN
    CREATE DATABASE panel;
  END IF;
END$$;
SQL

# Create minimal MySQL user/db for the default WP container if not present
mysql -h mysql -uroot -proot <<'SQL'
CREATE USER IF NOT EXISTS 'wp'@'%' IDENTIFIED BY 'wp';
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp'@'%';
FLUSH PRIVILEGES;
SQL

# Optional: pre-warm WordPress files by hitting the origin via Caddy
curl -sS http://caddy/ >/dev/null || true

echo "✅ Databases ready. Next: run your panel/mirror apps."
echo " - Origin WP: http://localhost:8080"
echo " - Mirror (Caddy -> your Actix on :9001): http://localhost:8001"
