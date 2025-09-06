# syntax=docker/dockerfile:1

FROM rust:1.77 AS builder
WORKDIR /app

# Pre-fetch dependencies
COPY Cargo.toml Cargo.lock ./
COPY panel/Cargo.toml panel/Cargo.toml
COPY mirror/Cargo.toml mirror/Cargo.toml
RUN mkdir panel/src mirror/src \
    && echo "fn main() {}" > panel/src/main.rs \
    && echo "fn main() {}" > mirror/src/main.rs \
    && cargo build --release -p panel \
    && rm -r panel/src mirror/src

# Build the application
COPY . .
RUN cargo build --release -p panel
# Install SQLx CLI for running migrations
RUN cargo install --locked sqlx-cli --features rustls,postgres

FROM debian:bookworm-slim
WORKDIR /app
RUN apt-get update \
    && apt-get install -y libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/panel /usr/local/bin/panel
COPY --from=builder /usr/local/cargo/bin/sqlx /usr/local/bin/sqlx
COPY panel/migrations ./migrations

ENV RUST_LOG=info
EXPOSE 8000
CMD ["sh", "-c", "sqlx migrate run && panel"]
