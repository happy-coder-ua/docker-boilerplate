# Nextcloud (Docker + Traefik)

This template runs **Nextcloud** with **MariaDB** and **Redis** behind **Traefik**.

## Requirements

- Traefik connected to external Docker network `${TRAEFIK_NETWORK}` (default: `proxy-public`).
- DNS record for `${DOMAIN_NAME}` pointing to your server.

## Local usage

1. Copy `.env.example` to `.env` and set values.
2. Start:

- `make up`

Then open: `https://${DOMAIN_NAME}`

## Important env vars

- `PROJECT_NAME` — container and router prefix.
- `DOMAIN_NAME` — host for Traefik rule.
- `TRAEFIK_NETWORK` — external Traefik network name.
- `MYSQL_*` — Nextcloud DB credentials.
- `NEXTCLOUD_ADMIN_*` — initial admin user/password.

## Production Deploy (CI/CD)

- Do **not** commit `.env`.
- CI creates/updates `.env` on the server.
- Push to `main` to deploy.

### GitHub Actions variables/secrets

Variables:

- `SERVER_HOST`
- `SERVER_USER`
- `PROJECT_PATH`
- `PROJECT_NAME`
- `DOMAIN_NAME`
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional)
- `REPO_URL` (optional)

Secrets:

- `SSH_PRIVATE_KEY`
- `REPO_SSH_KEY` (optional)

Set `MYSQL_*`, `NEXTCLOUD_ADMIN_*` and optional Nextcloud vars directly in `.env` on server (or commit safe defaults in `.env.example` and override securely).

### GitLab CI variables

- `SERVER_HOST`
- `SERVER_USER`
- `SSH_PRIVATE_KEY`
- `PROJECT_PATH`
- `PROJECT_NAME`
- `DOMAIN_NAME`
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional)
- `REPO_URL`
- `REPO_SSH_KEY` (optional)
- `GIT_BRANCH` (optional)
