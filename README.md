# Docker Project Generator

This is a CLI tool to generate production-ready Docker projects for your VPS. It helps you set up a **Global Proxy (Traefik)** and generate standalone **Web** or **Bot** projects that automatically connect to it.

## How it works

This repository is NOT your project. It is a **Generator**.
You clone this repo once, and use it to spawn as many independent projects as you need.

## Usage

### Option 1: Remote (Recommended)
You can run the generator directly without cloning the repo manually:

```bash
# Replace with your actual URL after pushing to GitHub
bash <(curl -s https://raw.githubusercontent.com/happy-coder-ua/docker-boilerplate/main/install.sh)
```

### Option 2: Local (For development)

1.  **Clone this generator**:
    ```bash
    git clone https://github.com/happy-coder-ua/docker-boilerplate.git generator
    cd generator
    ```

2.  **Run the generator**:
    ```bash
    ./install.sh
    ```

3.  **Select what you want to create**:
    *   **Global Proxy**: Creates a `global-proxy` folder. Run this once per server.
    *   **Web Project**: Creates a new folder (e.g., `my-shop`) with a Next.js app configured for your domain.
    *   **Telegram Bot**: Creates a new folder (e.g., `support-bot`) with a Node.js bot.

## Result

Each generated project is **completely independent**.
*   It has its own `docker-compose.yml`.
*   It has its own `.env`.
*   It is initialized as a **new Git repository** (`git init`).

You can simply `cd` into the new folder, commit it, and push it to its own GitHub repository.

## Architecture

All generated projects are pre-configured to work with the **Global Proxy**.
*   **Traefik** listens on ports 80/443.
*   **Projects** connect to the `proxy-public` Docker network.
*   Traefik automatically routes traffic to the correct container based on the domain name in `.env`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
