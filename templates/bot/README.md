# Telegram Bot Boilerplate

This is a standalone Telegram Bot project (Node.js/Telegraf) ready to be deployed with Docker.

## Setup

1.  **Clone**: Clone this repo to your server.
2.  **Env**: Copy `.env.example` to `.env` and add your `BOT_TOKEN`.
    ```bash
    cp .env.example .env
    # Edit .env
    ```
3.  **Run**:
    ```bash
    docker-compose up -d --build
    ```


## Network
It connects to the `proxy-public` network by default, which is useful if you plan to use Webhooks with Traefik later. If you only use Long Polling, this is optional but harmless.
