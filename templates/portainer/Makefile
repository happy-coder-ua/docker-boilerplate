.PHONY: help up down restart ps logs

COMPOSE ?= docker compose

# Portainer template has only one compose file (plus optional docker-compose.override.yml).

help:
	@echo "Usage:"
	@echo "  make up"
	@echo "  make down"
	@echo ""
	@echo "Other: make logs | make ps"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200
