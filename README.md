# Docker Project Generator

This is a CLI tool to generate production-ready Docker projects for your VPS. It helps you set up a **Global Proxy (Traefik)** and generate standalone **Web** or **Bot** projects that automatically connect to it.

## How it works

This repository is NOT your project. It is a **Generator**.
You use it to spawn as many independent projects as you need, directly on your server.

## Usage

Run the generator directly:

```bash
bash <(curl -s "https://raw.githubusercontent.com/happy-coder-ua/docker-boilerplate/main/install.sh?v=$(date +%s)")
```

The script will automatically check if Docker is installed and offer to install it if missing.

Follow the interactive menu to:
*   **Global Proxy**: Create a `global-proxy` folder (Run this once per server).
*   **Web Project**: Create a new folder (e.g., `my-shop`) with a Next.js app.
*   **Telegram Bot**: Create a new folder (e.g., `support-bot`) with a Node.js bot.

### Local Development (Optional)

If you want to contribute or modify the templates:

1.  **Clone this generator**:
    ```bash
    git clone https://github.com/happy-coder-ua/docker-boilerplate.git generator
    cd generator
    ```

2.  **Run locally**:
    ```bash
    ./install.sh
    ```


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
