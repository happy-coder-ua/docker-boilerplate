.PHONY: help up down restart ps logs

COMPOSE ?= docker compose

help:
	@echo "Usage:"
	@echo "  make up"
	@echo "  make down"
	@echo "  make restart"
	@echo "  make ps"
	@echo "  make logs"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200
