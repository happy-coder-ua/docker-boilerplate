# Portainer (Docker + Traefik)

This template runs **Portainer CE** behind **Traefik** using Host routing.

## Requirements

- A Traefik instance connected to the external Docker network `${TRAEFIK_NETWORK}` (default: `proxy-public`).
- A DNS record for `${DOMAIN_NAME}` pointing to your server.

## Local usage

1. Copy `.env.example` to `.env` and set values.
2. Start:

- `make prod up`

Then open: `https://${DOMAIN_NAME}`

Portainer will ask you to create an admin user on first run.

## Optional: add Traefik Basic Auth

If you want an extra auth prompt *before* Portainer, create `docker-compose.override.yml` with Traefik middleware labels.

Generate bcrypt htpasswd (example):

- `docker run --rm httpd:alpine htpasswd -Bbn admin 'your-password'`

Put the full `admin:$2y$...` line into `.env` as `PORTAINER_BASIC_AUTH_USERS=...`.

If you generate the project via `install.sh`, it can create the override file for you.
