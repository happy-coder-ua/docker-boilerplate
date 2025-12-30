.PHONY: help dev prod up down restart build ps logs

COMPOSE ?= docker compose

# Usage style:
#   make dev up
#   make dev down
#   make prod up
#   make prod down

MODE ?= prod
ifneq (,$(filter dev,$(MAKECMDGOALS)))
MODE := dev
endif
ifneq (,$(filter prod,$(MAKECMDGOALS)))
MODE := prod
endif

COMPOSE_FILE :=
ifeq ($(MODE),dev)
COMPOSE_FILE := -f docker-compose.dev.yml
endif

help:
	@echo "Usage:"
	@echo "  make dev up"
	@echo "  make dev down"
	@echo "  make prod up"
	@echo "  make prod down"
	@echo ""
	@echo "Other: make prod logs | make dev logs | make prod ps | make dev ps"

dev:
	@:

prod:
	@:

up:
	$(COMPOSE) $(COMPOSE_FILE) up -d --build

down:
	$(COMPOSE) $(COMPOSE_FILE) down

restart: down up

build:
	$(COMPOSE) $(COMPOSE_FILE) build

ps:
	$(COMPOSE) $(COMPOSE_FILE) ps

logs:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=200
