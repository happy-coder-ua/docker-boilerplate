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

If you want an extra auth prompt *before* Portainer, you can add Traefik Basic Auth middleware labels.

CI/CD recommended:

- Set `PORTAINER_BASIC_AUTH_USER` (variable) and `PORTAINER_BASIC_AUTH_PASSWORD` (secret/masked).
- The deploy workflow will generate `docker-compose.override.yml` on the server.
- If one of them is missing, the workflow removes its generated override (auth disabled).

Manual option:

1. Generate bcrypt htpasswd (example): `docker run --rm httpd:alpine htpasswd -Bbn admin 'your-password'`
2. Put the resulting `admin:$2y$...` line **directly** into `docker-compose.override.yml` (not `.env`).
	- Note: Docker Compose treats `$` as interpolation marker, so escape dollars in label values: `admin:$$2y$$...`.

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
- `PORTAINER_BASIC_AUTH_USER` (optional; enables Basic Auth when password is also set)
- `REPO_URL` (optional; defaults to the current GitHub repo)

Secrets (Repository → Settings → Secrets):

- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `REPO_SSH_KEY` (optional; server → GitHub Deploy Key private key; needed for private repos)
- `PORTAINER_BASIC_AUTH_PASSWORD` (optional; Basic Auth password; keep as secret)

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
- `PORTAINER_BASIC_AUTH_USER` (optional)
- `PORTAINER_BASIC_AUTH_PASSWORD` (optional; set as masked/protected variable)
- `REPO_URL` (required; e.g. `https://github.com/<owner>/<repo>.git`)
- `REPO_SSH_KEY` (optional; Deploy Key private key for private repos)
- `GIT_BRANCH` (optional; defaults to GitLab branch)
