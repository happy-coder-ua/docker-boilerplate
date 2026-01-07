# Traefik Global Proxy Boilerplate

This repository contains the configuration for the main Traefik proxy server. It handles SSL termination and routing for all your other Docker projects on the same VPS.

## Setup

1.  **DNS**: Point your domains (A-records) to this server's IP.
2.  **Env**: Copy `.env.example` to `.env` and set your email:
    ```bash
    cp .env.example .env
    # Edit .env and set ACME_EMAIL=your-email@example.com
    ```
3.  **Permissions**:
    ```bash
    chmod 600 traefik/acme.json
    ```
4.  **Run**:
    ```bash
    docker compose up -d
    ```

## Optional: Traefik Dashboard (HTTPS + Basic Auth)

By default, the dashboard is bound to `127.0.0.1:8080` (not public).

If you want to expose it via a domain (recommended only with Basic Auth), create `docker-compose.override.yml`:

1. Generate bcrypt htpasswd (example):
    - `docker run --rm httpd:alpine htpasswd -Bbn admin 'your-password'`
2. Put the full `admin:$2y$...` line into `.env` as `TRAEFIK_DASHBOARD_BASIC_AUTH_USERS=...`.
3. Set `TRAEFIK_DASHBOARD_DOMAIN=traefik.yourdomain.com` in `.env`.
4. Create `docker-compose.override.yml` with router+middleware labels (see the generator or copy from docs).


## Network
This project creates a Docker network named `proxy-public`. All other projects (Web, Bot) must connect to this network to be accessible via domains.
