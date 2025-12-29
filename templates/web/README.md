# Next.js Web Boilerplate

This is a standalone Next.js project ready to be deployed behind a Traefik proxy.

## Setup

1.  **Clone**: Clone this repo to your server.
2.  **Env**: Copy `.env.example` to `.env` and set your domain:
    ```bash
    cp .env.example .env
    # Edit .env and set DOMAIN_NAME=yourdomain.com
    ```
3.  **Run**:
    ```bash
    docker compose up -d --build
    ```


## Requirements
You must have the **Traefik Global Proxy** running on the same server and the `proxy-public` network must exist.
