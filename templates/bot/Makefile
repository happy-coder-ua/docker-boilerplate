.PHONY: help up down restart build ps logs

COMPOSE ?= docker compose

help:
	@echo "Targets:"
	@echo "  make up      Start stack (docker-compose.yml)"
	@echo "  make down    Stop stack"
	@echo "  make build   Build images"
	@echo "  make logs    Follow logs"
	@echo "  make ps      Show container status"

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
