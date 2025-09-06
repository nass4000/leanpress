# leanpress
A WordPress hosting service where users just drop in their backup, and your system auto-enchants (optimizes + deploys) it to a high-speed environment.

## Running with Docker

The repository includes a minimal Docker setup for local development. It starts a PostgreSQL database and the `panel` API service.

```bash
docker compose up --build
```

The API will be available at <http://localhost:8000> and connects to a PostgreSQL instance using the URL `postgres://panel:panel@postgres:5432/panel`.
