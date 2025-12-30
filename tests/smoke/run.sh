#!/usr/bin/env bash
set -euo pipefail

log() {
  printf "\n==> %s\n" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

ROOT="$(repo_root)"
TEMPLATES_DIR="$ROOT/templates"

require_cmd docker

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin is required (docker compose)" >&2
  exit 1
fi

USER_ID="$(id -u)"
GROUP_ID="$(id -g)"

TMP="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

ensure_proxy_network() {
  if ! docker network inspect proxy-public >/dev/null 2>&1; then
    docker network create proxy-public >/dev/null
  fi
}

write_env() {
  local dir="$1"
  local project_name="$2"
  local domain_name="$3"
  local traefik_network="$4"

  cat >"$dir/.env" <<EOF
PROJECT_NAME=$project_name
DOMAIN_NAME=$domain_name
TRAEFIK_NETWORK=$traefik_network
EOF
}

validate_compose() {
  local dir="$1"
  (cd "$dir" && docker compose --env-file .env config >/dev/null)
  if [ -f "$dir/docker-compose.dev.yml" ]; then
    (cd "$dir" && docker compose --env-file .env -f docker-compose.dev.yml config >/dev/null)
  fi
}

build_dockerfile() {
  local dir="$1"
  local tag="$2"
  (cd "$dir" && docker build -t "$tag" . >/dev/null)
}

# -------------------- Next.js --------------------
log "Test: templates/nextjs (generate + overlay + compose config + docker build)"
ensure_proxy_network

NEXT_DIR="$TMP/nextjs-app"
mkdir -p "$TMP"

# Generate a real Next.js app (non-interactive)
docker run --rm \
  -v "$TMP:/work" -w /work \
  -e HOME=/tmp \
  --user "$USER_ID:$GROUP_ID" \
  node:lts-alpine \
  sh -lc "npx --yes create-next-app@latest nextjs-app --yes --no-git" >/dev/null

test -d "$NEXT_DIR" || { echo "Next.js generation failed" >&2; exit 1; }

# Overlay boilerplate
cp "$TEMPLATES_DIR/nextjs/Dockerfile" "$NEXT_DIR/"
cp "$TEMPLATES_DIR/nextjs/docker-compose.yml" "$NEXT_DIR/"
cp "$TEMPLATES_DIR/nextjs/docker-compose.dev.yml" "$NEXT_DIR/" 2>/dev/null || true
cp "$TEMPLATES_DIR/nextjs/.env.example" "$NEXT_DIR/" 2>/dev/null || true

# Sanity: lock file should exist for npm ci in Dockerfile
if [ ! -f "$NEXT_DIR/package-lock.json" ]; then
  echo "Expected package-lock.json from create-next-app (required by npm ci in Dockerfile)" >&2
  exit 1
fi

write_env "$NEXT_DIR" "nextjs-app" "nextjs-app.docker.localhost" "proxy-public"
validate_compose "$NEXT_DIR"
build_dockerfile "$NEXT_DIR" "smoke-nextjs:latest"

# -------------------- React + Vite --------------------
log "Test: templates/vite-react (generate + overlay + compose config + docker build)"
ensure_proxy_network

VITE_DIR="$TMP/vite-app"

docker run --rm \
  -v "$TMP:/work" -w /work \
  -e HOME=/tmp \
  --user "$USER_ID:$GROUP_ID" \
  node:lts-alpine \
  sh -lc "npm create --yes vite@latest vite-app -- --template react && cd vite-app && npm install" >/dev/null

test -d "$VITE_DIR" || { echo "Vite generation failed" >&2; exit 1; }

cp "$TEMPLATES_DIR/vite-react/Dockerfile" "$VITE_DIR/"
cp "$TEMPLATES_DIR/vite-react/nginx.conf" "$VITE_DIR/"
cp "$TEMPLATES_DIR/vite-react/docker-compose.yml" "$VITE_DIR/"
cp "$TEMPLATES_DIR/vite-react/docker-compose.dev.yml" "$VITE_DIR/" 2>/dev/null || true
cp "$TEMPLATES_DIR/vite-react/.env.example" "$VITE_DIR/" 2>/dev/null || true

write_env "$VITE_DIR" "vite-app" "vite-app.docker.localhost" "proxy-public"
validate_compose "$VITE_DIR"
build_dockerfile "$VITE_DIR" "smoke-vite-react:latest"

# -------------------- Bot --------------------
log "Test: templates/bot (overlay + compose config + docker build)"
ensure_proxy_network

BOT_DIR="$TMP/bot-app"
cp -r "$TEMPLATES_DIR/bot" "$BOT_DIR"

# Bot template needs a BOT_TOKEN for env wiring; Traefik can stay disabled.
cat >"$BOT_DIR/.env" <<EOF
PROJECT_NAME=bot-app
BOT_TOKEN=000000:dummy
DOMAIN_NAME=
TRAEFIK_NETWORK=proxy-public
TRAEFIK_ENABLE=false
EOF

validate_compose "$BOT_DIR"
build_dockerfile "$BOT_DIR" "smoke-bot:latest"

log "OK: all template smoke tests passed"