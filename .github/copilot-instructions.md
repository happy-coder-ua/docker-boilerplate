# Docker Boilerplate Generator (Agent Instructions)

This repository is a **generator**, not a deployable app. The only “runtime” is `install.sh`, which scaffolds independent projects from `templates/`.

## Language
- Chat: Ukrainian.
- Code/comments/docs: English.

## Big Picture
- Core entrypoint: `install.sh` (interactive TUI with ↑/↓, generates projects in the current directory).
- Blueprints live in `templates/`:
  - `templates/traefik/`: global proxy (Traefik) project.
  - `templates/nextjs/`: Next.js web app (Docker + CI/CD).
  - `templates/vite-react/`: React + Vite web app (Docker + CI/CD).
  - `templates/bot/`: Node.js Telegram bot (Docker + CI/CD).
  - `templates/portainer/`: Portainer (Docker UI) behind Traefik (+ optional Basic Auth).

## Non-Negotiable Conventions
- **No in-place patching**: avoid `sed -i`/mutating copied files after the fact. Prefer copying templates as-is and writing `.env` via heredocs.
- **Env-driven Compose**: templates rely on `PROJECT_NAME`, `DOMAIN_NAME`, `TRAEFIK_NETWORK` (and `ACME_EMAIL` for Traefik). Use `${VAR?message}` in compose to fail fast.
- **Networking**: services must join an external Traefik network (default `proxy-public`). Compose should keep:
  - `networks: proxy-public: external: true`
  - `name: ${TRAEFIK_NETWORK?TRAEFIK_NETWORK must be set}`
- **Traefik labels**: route by host and use `entrypoints=https` (see templates’ `docker-compose.yml`).

## Generator Implementation Notes
- Project creation uses Dockerized Node tooling (e.g., `node:lts-alpine` + `npm create ...`) to avoid local Node installs.
- File ownership can still get messy; keep the existing “fix permissions” approach (Docker `--user` first, fallback `sudo chown`).

## CI/CD Pattern (Templates)
- `.env` is **not committed**; CI creates it on the server during deploy.
- GitHub Actions uses a **reusable workflow** (`.github/workflows/deploy.yml`) called by `main.yml`.
- Gating: do not rely on `secrets.*` in `jobs.<id>.if` (context restrictions). Use `vars.*` for job-level gating; validate secrets inside the reusable workflow.

## Developer Workflow
- Change future generated projects by editing `templates/**` (not by editing generated repos).
- Smoke test: run `./install.sh`, generate a dummy project, verify `.env` + `docker-compose*.yml`, then delete the dummy folder (may require `sudo rm -rf`).
