# Telegram Bot Boilerplate

This is a standalone Telegram Bot project (Node.js/Telegraf) ready to be deployed with Docker.

## Intended Workflow

- Generate (locally or on a VPS) and develop locally.
- Push to Git.
- Deploy to VPS via CI/CD (GitHub Actions / GitLab CI).

## Local Setup

1.  **Env**: Copy `.env.example` to `.env` and add your `BOT_TOKEN`.
    ```bash
    cp .env.example .env
    # Edit .env
    ```
2.  **Run**:
    ```bash
    docker compose up -d --build
    ```

## Make Commands

If you prefer short commands, use the included `Makefile`:

```bash
make up
make down
make logs
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
- `TRAEFIK_ENABLE` (optional)
- `ADMIN_IDS` (optional)
- `REPO_URL` (optional; defaults to the current GitHub repo)

Secrets (Repository → Settings → Secrets):

- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `BOT_TOKEN` (optional)
- `REPO_SSH_KEY` (optional; server → GitHub Deploy Key private key; needed for private repos)

### GitLab CI variables

Add these in GitLab: **Settings → CI/CD → Variables**.

- `SERVER_HOST`
- `SERVER_USER`
- `SSH_PRIVATE_KEY` (required; CI → server SSH key)
- `PROJECT_PATH`
- `PROJECT_NAME`
- `BOT_TOKEN` (required)
- `DOMAIN_NAME` (optional)
- `TRAEFIK_NETWORK`
- `TRAEFIK_ENTRYPOINT` (optional)
- `TRAEFIK_ENABLE` (optional)
- `REPO_URL` (required; e.g. `https://github.com/<owner>/<repo>.git`)
- `REPO_SSH_KEY` (optional; Deploy Key private key for private repos)
- `GIT_BRANCH` (optional; defaults to GitLab branch)


## Network
It connects to the `proxy-public` network by default, which is useful if you plan to use Webhooks with Traefik later. If you only use Long Polling, this is optional but harmless.
