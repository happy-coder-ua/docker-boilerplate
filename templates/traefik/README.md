# Traefik Global Proxy Boilerplate

This repository contains the configuration for the main Traefik proxy server. It handles SSL termination and routing for all your other Docker projects on the same VPS.

## Setup

1.  **DNS**: Point your domains (A-records) to this server's IP.
2.  **Env**: Copy `.env.example` to `.env` and set your email:
    ```bash
    cp .env.example .env
    # Edit .env and set ACME_EMAIL=your-email@example.com
    ```
3.  **Permissions**:
    ```bash
    chmod 600 traefik/acme.json
    ```
4.  **Run**:
    ```bash
    docker-compose up -d
    ```


## Network
This project creates a Docker network named `proxy-public`. All other projects (Web, Bot) must connect to this network to be accessible via domains.
