.PHONY: help dev prod up down restart ps logs

COMPOSE ?= docker compose

# Traefik template has only one compose file.
# We keep the same UX as other templates:
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
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200
