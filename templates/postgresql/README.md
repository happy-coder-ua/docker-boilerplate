# PostgreSQL + pgAdmin (Docker + Traefik)

This template runs **PostgreSQL** with **pgAdmin** behind **Traefik**.

- PostgreSQL is exposed on localhost only (default `127.0.0.1:5432`) for security.
- pgAdmin is accessible via Traefik with Host routing and TLS.

## Requirements

- Traefik connected to external Docker network `${TRAEFIK_NETWORK}` (default: `proxy-public`).
- DNS record for `${DOMAIN_NAME}` pointing to your server (for pgAdmin access).

## Usage

1. Copy `.env.example` to `.env` and set values.
2. Start:

- `make up`

Then open: `https://${DOMAIN_NAME}` for pgAdmin.

PostgreSQL is available at `localhost:${POSTGRES_PORT}` (default `5432`, bound to 127.0.0.1 only).

## Important env vars

- `PROJECT_NAME` — container and router prefix.
- `DOMAIN_NAME` — host for pgAdmin Traefik rule.
- `TRAEFIK_NETWORK` — external Traefik network name.
- `POSTGRES_DB` — database name (default: `app`).
- `POSTGRES_USER` — database user (default: `postgres`).
- `POSTGRES_PASSWORD` — database password (**required**).
- `POSTGRES_PORT` — host port for PostgreSQL (default: `5432`).
- `PGADMIN_DEFAULT_EMAIL` — pgAdmin login email (**required**).
- `PGADMIN_DEFAULT_PASSWORD` — pgAdmin login password (**required**).

## Connecting pgAdmin to PostgreSQL

In pgAdmin, add a new server with:

- **Host**: `db` (the Docker service name)
- **Port**: `5432`
- **Username**: value of `POSTGRES_USER`
- **Password**: value of `POSTGRES_PASSWORD`
