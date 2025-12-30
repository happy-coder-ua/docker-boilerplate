# Docker Boilerplate Generator Instructions

This repository is a **Generator**, not a standalone application. It uses `install.sh` to spawn independent Docker-based projects (Web, Bot, Traefik) from blueprints in `templates/`.

## Language & Communication
- **Chat/Conversation**: Ukrainian (Українська).
- **Code, Comments, Documentation**: English.

## Architecture & Data Flow
- **`install.sh`**: The core logic. It prompts the user, copies files from `templates/`, and uses `sed` to inject configuration (Domain, Email, Project Name).
- **`templates/`**: Contains the "source code" for generated projects.
  - `nextjs/`: Next.js + Docker (Standalone mode).
  - `bot/`: Node.js Telegram Bot.
  - `traefik/`: Global reverse proxy configuration.
- **Networking**: All generated services connect to an external Docker network named `proxy-public` to be exposed via Traefik.

## Development Workflow
1.  **Modify Templates**: To change how future projects look, edit files in `templates/`.
2.  **Modify Logic**: To change *how* projects are created (e.g., permission fixes, prompts), edit `install.sh`.
3.  **Test**: Run `./install.sh` locally to generate a dummy project.
    - *Do not* commit the generated dummy project.
    - Verify `docker-compose.yml` and `.env` in the generated folder.

## Project-Specific Patterns
- **Permission Handling**: `install.sh` must handle file ownership. Since `create-next-app` runs in Docker (often as root), the script explicitly fixes permissions using `sudo chown` or Docker-based `chown`.
- **Environment Variables**:
  - **Local**: `DOMAIN_NAME` is set in `.env` (e.g., `app.docker.localhost`).
  - **Production**: CI/CD templates (`.github`, `.gitlab-ci.yml`) inject `DOMAIN_NAME` from Secrets/Variables during deployment.
- **Next.js Generation**: The script runs `npx create-next-app` inside a temporary Docker container to avoid local Node.js dependencies. It then patches `next.config.js` to ensure `output: "standalone"`.

## Common Commands
- **Run Generator**: `./install.sh`
- **Clean Up Test**: `sudo rm -rf <generated-folder-name>` (often required due to Docker permissions).

## Critical Rules
- **Never hardcode domains** in templates. Use placeholders or `sed` replacement targets.
- **Preserve `proxy-public`**: All `docker-compose.yml` templates must define this external network.
- **CI/CD**: Ensure templates include logic to generate `.env` files on the remote server, as they are not committed to Git.
