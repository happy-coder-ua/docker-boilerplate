# Next.js Web Boilerplate

This is a standalone Next.js project ready to be deployed behind a Traefik proxy.

## Intended Workflow (Local Generation)

- Generate and develop locally.
- Push to Git.
- Deploy to VPS via CI/CD (GitHub Actions / GitLab CI).

This project is not meant to be generated on a VPS.

## Local Setup

1.  **Env**: Copy `.env.example` to `.env` and set your domain:
    ```bash
    cp .env.example .env
    # Edit .env and set DOMAIN_NAME=yourdomain.com
    ```
2.  **Run**:
    ```bash
    docker compose up -d --build
    ```

## Production Deploy (CI/CD)

- Do **not** commit `.env`.
- Configure GitHub Actions/GitLab CI variables and secrets.
- Push to `main` to deploy.


## Requirements
You must have the **Traefik Global Proxy** running on the same server and the `proxy-public` network must exist.
