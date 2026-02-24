# Traefik Global Proxy Boilerplate

This repository contains the configuration for the main Traefik proxy server. It handles SSL termination and routing for all your other Docker projects on the same VPS.

## Setup

1.  **DNS**: Point your domains (A-records) to this server's IP.
2.  **Env**: The `.env` file is automatically created during installation with `ACME_EMAIL` set.
3.  **acme.json**: Already initialized and permissions set automatically.
4.  **Run**:
    ```bash
    docker compose up -d
    ```

## Troubleshooting Certificate Issues

### ❌ Certificates Not Being Acquired

If you see errors in the logs about certificate acquisition failing, check:

#### 1. **DNS Resolution**
   Must resolve to this server's public IP address:
   ```bash
   nslookup your-domain.com
   dig your-domain.com
   ```

#### 2. **Ports Accessibility**
   - Port 80 (HTTP) must be accessible from the internet for ACME challenge
   - Port 443 (HTTPS) must also be open
   - Check firewall rules and port forwarding

#### 3. **Check Traefik Logs**
   ```bash
   docker logs traefik -f
   ```
   Look for: `Storing ACME account...` (certificate being requested)

#### 4. **Verify acme.json**
   ```bash
   ls -la traefik/acme.json  # Should show -rw------- (600)
   echo '{}' > traefik/acme.json  # Reinitialize if needed
   chmod 600 traefik/acme.json
   docker compose down && docker compose up -d
   ```

#### 5. **Email Configuration**
   - Check `.env` has a valid `ACME_EMAIL`
   - Let's Encrypt sends expiration notices to this email

## Optional: Traefik Dashboard (HTTPS + Basic Auth)

By default, the dashboard is bound to `127.0.0.1:8080` (not public).

If you want to expose it via a domain (recommended only with Basic Auth), use CI/CD to generate `docker-compose.override.yml` on the server.

CI/CD (no hashes in variables):

- Variable: `TRAEFIK_DASHBOARD_DOMAIN`
- Variable: `TRAEFIK_DASHBOARD_BASIC_AUTH_USER`
- Secret/masked: `TRAEFIK_DASHBOARD_BASIC_AUTH_PASSWORD`

When all three are set, the deploy workflow generates a bcrypt htpasswd line on the server and writes `docker-compose.override.yml`.
If any of them is missing, the workflow removes its generated override (dashboard stays private on `127.0.0.1:8080`).

Manual option (advanced):

1. Generate bcrypt htpasswd: `docker run --rm httpd:alpine htpasswd -Bbn admin 'your-password'`
2. Put the resulting `admin:$2y$...` line directly into `docker-compose.override.yml`.
   - Note: escape dollars for Docker Compose label values: `admin:$$2y$$...`.
3. Set `TRAEFIK_DASHBOARD_DOMAIN=traefik.yourdomain.com` in `.env`.


## Network
This project creates a Docker network named `proxy-public`. All other projects (Web, Bot) must connect to this network to be accessible via domains.
