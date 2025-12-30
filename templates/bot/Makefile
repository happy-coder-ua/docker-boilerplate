.PHONY: help dev prod up down restart build ps logs

COMPOSE ?= docker compose

# Bot template has only one compose file, but we keep the same UX:
#   make dev up / make prod up

help:
	@echo "Usage:"
	@echo "  make dev up"
	@echo "  make dev down"
	@echo "  make prod up"
	@echo "  make prod down"
	@echo ""
	@echo "Other: make logs | make ps"

dev:
	@:

prod:
	@:

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
