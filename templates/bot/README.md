# Telegram Bot Boilerplate

This is a standalone Telegram Bot project (Node.js/Telegraf) ready to be deployed with Docker.

## Intended Workflow (Local Generation)

- Generate and develop locally.
- Push to Git.
- Deploy to VPS via CI/CD (GitHub Actions / GitLab CI).

This project is not meant to be generated on a VPS.

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


## Network
It connects to the `proxy-public` network by default, which is useful if you plan to use Webhooks with Traefik later. If you only use Long Polling, this is optional but harmless.
