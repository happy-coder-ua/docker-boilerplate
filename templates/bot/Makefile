.PHONY: help up down restart build ps logs

COMPOSE ?= docker compose

help:
	@echo "Usage:"
	@echo "  make up"
	@echo "  make down"
	@echo ""
	@echo "Other: make logs | make ps"

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
