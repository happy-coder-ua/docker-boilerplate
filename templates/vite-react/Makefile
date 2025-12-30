.PHONY: help up down restart build ps logs dev dev-down dev-restart

COMPOSE ?= docker compose

help:
	@echo "Targets:"
	@echo "  make dev         Start dev stack (docker-compose.dev.yml)"
	@echo "  make dev-down    Stop dev stack"
	@echo "  make up          Start prod-like stack (docker-compose.yml)"
	@echo "  make down        Stop prod-like stack"
	@echo "  make build       Build prod-like images"
	@echo "  make logs        Follow logs (prod-like)"
	@echo "  make ps          Show container status"

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

restart: down up

build:
	$(COMPOSE) build

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200

dev:
	$(COMPOSE) -f docker-compose.dev.yml up -d --build

dev-down:
	$(COMPOSE) -f docker-compose.dev.yml down

dev-restart: dev-down dev
