# Portainer (Docker + Traefik)

This template runs **Portainer CE** behind **Traefik** using Host routing.

## Requirements

- A Traefik instance connected to the external Docker network `${TRAEFIK_NETWORK}` (default: `proxy-public`).
- A DNS record for `${DOMAIN_NAME}` pointing to your server.

## Local usage

1. Copy `.env.example` to `.env` and set values.
2. Start:

- `make up`

Then open: `https://${DOMAIN_NAME}`

Portainer will ask you to create an admin user on first run.

## Optional: add Traefik Basic Auth

If you want an extra auth prompt *before* Portainer, create `docker-compose.override.yml` with Traefik middleware labels.

Generate bcrypt htpasswd (example):

- `docker run --rm httpd:alpine htpasswd -Bbn admin 'your-password'`

Put the full `admin:$2y$...` line into `.env` as `PORTAINER_BASIC_AUTH_USERS=...`.

If you generate the project via `install.sh`, it can create the override file for you.

## Production Deploy (CI/CD)

- Do **not** commit `.env`.
- Configure GitHub Actions/GitLab CI variables and secrets.
- Push to `main` to deploy.

### GitHub Actions variables/secrets

Variables (Repository → Settings → Variables):

- `SERVER_HOST`
- `SERVER_USER`
- `PROJECT_PATH`
- `PROJECT_NAME`
- `DOMAIN_NAME`
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional; e.g. `websecure` if your Traefik doesn't have `https`)
- `PORTAINER_BASIC_AUTH_USERS` (optional)
- `REPO_URL` (optional; defaults to the current GitHub repo)

Secrets (Repository → Settings → Secrets):

- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `REPO_SSH_KEY` (optional; server → GitHub Deploy Key private key; needed for private repos)

## GitLab CI variables

Add these in GitLab: **Settings → CI/CD → Variables**.

- `SERVER_HOST`
- `SERVER_USER`
- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `PROJECT_PATH`
- `PROJECT_NAME`
- `DOMAIN_NAME`
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional)
- `PORTAINER_BASIC_AUTH_USERS` (optional)
- `REPO_URL` (required; e.g. `https://github.com/<owner>/<repo>.git`)
- `REPO_SSH_KEY` (optional; Deploy Key private key for private repos)
- `GIT_BRANCH` (optional; defaults to GitLab branch)
