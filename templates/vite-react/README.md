# React + Vite Boilerplate

This is a standalone React (Vite) project ready to be deployed behind a Traefik proxy.

## Intended Workflow (Local Generation)

- Generate and develop locally.
- Push to Git.
- Deploy to VPS via CI/CD (GitHub Actions / GitLab CI).

This project is not meant to be generated on a VPS.

## Local Setup

1. **Env**: Copy `.env.example` to `.env` and set your domain.
   ```bash
   cp .env.example .env
   # Edit .env and set DOMAIN_NAME=yourdomain.com
   ```

2. **Run (prod-like)**:
   ```bash
   docker compose up -d --build
   ```

3. **Run (dev)**:
   ```bash
   docker compose -f docker-compose.dev.yml up
   ```

## Make Commands

If you prefer short commands, use the included `Makefile`:

```bash
make dev        # start dev stack
make dev-down   # stop dev stack
make up         # prod-like stack
make down       # stop
make logs       # follow logs
```

## Production Deploy (CI/CD)

- Do **not** commit `.env`.
- Configure GitHub Actions/GitLab CI variables and secrets.
- Push to `main` to deploy.

## Requirements

You must have the **Traefik Global Proxy** running on the same server and the `proxy-public` network must exist.
