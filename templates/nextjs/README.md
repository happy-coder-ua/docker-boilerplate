# Next.js Web Boilerplate

This is a standalone Next.js project ready to be deployed behind a Traefik proxy.

## Intended Workflow

- Generate (locally or on a VPS) and develop locally.
- Push to Git.
- Deploy to VPS via CI/CD (GitHub Actions / GitLab CI).

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

## Make Commands

If you prefer short commands, use the included `Makefile`:

```bash
make dev up
make dev down
make prod up
make prod down
make prod logs
```

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
- `REPO_URL` (optional; defaults to the current GitHub repo)

Secrets (Repository → Settings → Secrets):

- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `REPO_SSH_KEY` (optional; server → GitHub Deploy Key private key; needed for private repos)

### GitLab CI variables

Add these in GitLab: **Settings → CI/CD → Variables**.

- `SERVER_HOST`
- `SERVER_USER`
- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `PROJECT_PATH`
- `PROJECT_NAME`
- `DOMAIN_NAME`
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional)
- `REPO_URL` (required; e.g. `https://github.com/<owner>/<repo>.git`)
- `REPO_SSH_KEY` (optional; Deploy Key private key for private repos)
- `GIT_BRANCH` (optional; defaults to GitLab branch)


## Requirements
You must have the **Traefik Global Proxy** running on the same server and the `proxy-public` network must exist.
