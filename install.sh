#!/bin/bash

# Version: 1.1.0

# Configuration
# !!! IMPORTANT: REPLACE THIS WITH YOUR ACTUAL GITHUB REPO URL !!!
REPO_URL="https://github.com/happy-coder-ua/docker-boilerplate.git"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Interactive Menu Function
interactive_menu() {
    local title="$1"
    shift
    local options=("$@")
    local cur=0
    local count=${#options[@]}
    local index=0
    local esc=$(echo -en "\033")
    local key=""

    # Hide cursor
    echo -en "\033[?25l"

    # Trap to ensure cursor is shown on exit
    trap "echo -en '\033[?25h'; exit" INT TERM EXIT

    while true; do
        # Clear screen for menu
        # clear # Optional: uncomment if you want full screen clear
        
        # Move cursor to top left (if clearing) or just print
        # For a simple inline menu that redraws, we can use tput or ANSI codes to move up.
        # But to keep it simple and robust, let's just clear the screen for the menu part.
        clear 

        echo -e "${BLUE}=============================================${NC}"
        echo -e "${BLUE}   $title${NC}"
        echo -e "${BLUE}=============================================${NC}"
        
        index=0
        for o in "${options[@]}"; do
            if [ "$index" == "$cur" ]; then
                echo -e " > ${GREEN}$o${NC}"
            else
                echo -e "   $o"
            fi
            index=$((index + 1))
        done
        echo -e "---------------------------------------------"
        echo -e "Use ${BLUE}UP/DOWN${NC} arrows to navigate, ${GREEN}ENTER${NC} to select."

        read -rsn1 key # Read 1 character

        if [[ $key == $esc ]]; then
            read -rsn2 key # Read 2 more chars
            if [[ $key == "[A" ]]; then # Up arrow
                cur=$((cur - 1))
                [ "$cur" -lt 0 ] && cur=$((count - 1))
            elif [[ $key == "[B" ]]; then # Down arrow
                cur=$((cur + 1))
                [ "$cur" -ge "$count" ] && cur=0
            fi
        elif [[ $key == "" ]]; then # Enter key
            break
        fi
    done

    # Show cursor again
    echo -en "\033[?25h"
    # Remove trap
    trap - INT TERM EXIT
    
    return $cur
}

# Helper for Yes/No questions
ask_yes_no() {
    local question="$1"
    local options=("Yes" "No")
    interactive_menu "$question" "${options[@]}"
    return $?
}

# Determine mode (Local vs Remote)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "$SCRIPT_DIR/templates" ]; then
    # Running locally (cloned repo)
    TEMPLATES_DIR="$SCRIPT_DIR/templates"
else
    # Running remotely (curl | bash)
    echo -e "${BLUE}>>> Remote execution detected.${NC}"
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is required but not installed.${NC}"
        exit 1
    fi

    echo -e "${BLUE}>>> Downloading templates from $REPO_URL...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    # Clone only the latest commit to save bandwidth
    if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &> /dev/null; then
        echo -e "${RED}Failed to download templates. Please check your internet connection or REPO_URL.${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    TEMPLATES_DIR="$TEMP_DIR/templates"
    
    # Ensure cleanup happens when script exits
    trap "rm -rf $TEMP_DIR" EXIT
fi

echo -e "${BLUE}=== Docker Project Generator v1.1.0 ===${NC}"
echo -e "This tool will generate a standalone project in the CURRENT directory."
echo -e "Current directory: $(pwd)"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed.${NC}"
    ask_yes_no "Do you want to install Docker automatically?"
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}>>> Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        echo -e "${GREEN}Docker installed successfully.${NC}"
    else
        echo -e "${RED}Please install Docker manually and run this script again.${NC}"
        exit 1
    fi
fi

ENV_TYPE="local"
echo -e "${GREEN}>>> Mode: Local Development (only)${NC}"
echo -e "${BLUE}>>> Generate locally -> push to git -> CI/CD deploys to VPS.${NC}"
echo ""

# Function to setup Traefik
setup_traefik() {
    echo -e "\n${BLUE}>>> Generating Global Proxy (Traefik)...${NC}"
    
    TARGET_DIR="global-proxy"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${RED}Directory '$TARGET_DIR' already exists.${NC}"
        ask_yes_no "Do you want to overwrite it?"
        if [ $? -eq 0 ]; then
            if [ -f "$TARGET_DIR/docker-compose.yml" ]; then
                echo -e "${BLUE}Stopping running containers...${NC}"
                (cd "$TARGET_DIR" && docker compose down 2>/dev/null || true)
            fi
            rm -rf "$TARGET_DIR"
        else
            read -p "Enter new name (or Ctrl+C to cancel): " TARGET_DIR
        fi
    fi

    cp -r "$TEMPLATES_DIR/traefik" "$TARGET_DIR"
    cd "$TARGET_DIR" || exit
    
    read -p "Enter email for Let's Encrypt SSL: " email

    # Write .env (no in-place edits)
    cat > .env <<EOF
ACME_EMAIL=$email
EOF
    
    chmod 600 traefik/acme.json

        # Dashboard Setup
        ask_yes_no "Do you want to enable the Traefik Dashboard with Basic Auth?"
        if [ $? -eq 0 ]; then
                enable_dashboard="y"
                read -p "Enter Dashboard Domain (e.g. traefik.yourdomain.com): " dashboard_domain
                read -p "Enter Dashboard Username: " dashboard_user
                read -s -p "Enter Dashboard Password: " dashboard_pass
                echo ""

                echo -e "${BLUE}>>> Generating password hash...${NC}"
                if ! docker image inspect httpd:alpine &> /dev/null; then
                         echo "Pulling helper image..."
                         docker pull -q httpd:alpine
                fi

                hash=$(docker run --rm httpd:alpine htpasswd -Bbn "$dashboard_user" "$dashboard_pass")
                # Escape $ -> $$ for docker-compose label values
                docker_compose_hash="${hash//\$/\$\$}"
        else
                enable_dashboard="n"
        fi

        # Generate traefik.yml (no in-place edits)
        if [[ "$enable_dashboard" =~ ^[Yy]$ ]]; then
                insecure_value="false"
        else
                insecure_value="true"
        fi

        cat > traefik/traefik.yml <<EOF
global:
    checkNewVersion: true
    sendAnonymousUsage: false

api:
    dashboard: true
    insecure: $insecure_value

providers:
    docker:
        endpoint: "unix:///var/run/docker.sock"
        exposedByDefault: false
    file:
        filename: /etc/traefik/dynamic.yml
        watch: true

entryPoints:
    http:
        address: ":80"
        http:
            redirections:
                entryPoint:
                    to: https
                    scheme: https

    https:
        address: ":443"

certificatesResolvers:
    myresolver:
        acme:
            email: "$email"
            storage: "/acme.json"
            httpChallenge:
                entryPoint: http
EOF

        # Generate docker-compose.yml (no in-place edits)
        cat > docker-compose.yml <<EOF
services:
    traefik:
        image: traefik:v3.6
        container_name: traefik
        restart: unless-stopped
        security_opt:
            - no-new-privileges:true
        environment:
            - DOCKER_API_VERSION=1.44
        command:
            - "--configFile=/etc/traefik/traefik.yml"
        ports:
            - "80:80"
            - "443:443"
EOF

        if [[ "$enable_dashboard" =~ ^[Yy]$ ]]; then
                cat >> docker-compose.yml <<EOF
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.dashboard.rule=Host(\`$dashboard_domain\`)"
            - "traefik.http.routers.dashboard.service=api@internal"
            - "traefik.http.routers.dashboard.middlewares=auth,dashboard-redirect"
            - "traefik.http.middlewares.auth.basicauth.users=$docker_compose_hash"
            - "traefik.http.middlewares.dashboard-redirect.redirectregex.regex=^https?://[^/]+/\$\$"
            - "traefik.http.middlewares.dashboard-redirect.redirectregex.replacement=https://$dashboard_domain/dashboard/"
            - "traefik.http.middlewares.dashboard-redirect.redirectregex.permanent=true"
            - "traefik.http.routers.dashboard.entrypoints=https"
            - "traefik.http.routers.dashboard.tls.certresolver=myresolver"
EOF
        else
                # Keep insecure dashboard port for dev-only usage
                cat >> docker-compose.yml <<EOF
            # Dashboard port (insecure mode - for dev only, or protect with middleware)
            - "8080:8080"
EOF
        fi

        cat >> docker-compose.yml <<EOF
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock:ro
            - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
            - ./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro
            - ./traefik/acme.json:/acme.json
        networks:
            - proxy-public

networks:
    proxy-public:
        name: proxy-public
EOF
    
    # Ensure proxy-public network exists
    if ! docker network inspect proxy-public >/dev/null 2>&1; then
        echo -e "${BLUE}>>> Creating external network 'proxy-public'...${NC}"
        docker network create proxy-public
    fi
    
    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "To start it:"
    echo -e "  cd $TARGET_DIR"
    echo -e "  docker compose up -d"
    if [[ "$enable_dashboard" =~ ^[Yy]$ ]]; then
        echo -e "  Dashboard: https://$dashboard_domain/dashboard/ (Don't forget the trailing slash!)"
    fi
}

# Function to setup Web
setup_web() {
    echo -e "\n${BLUE}>>> Generating New Web Project...${NC}"
    
    read -p "Enter project name (folder name): " folder_name
    
    traefik_network="proxy-public"
    echo -e "Enter the domain for your LOCAL environment (e.g., ${folder_name}.docker.localhost)."
    read -p "Local Domain [${folder_name}.docker.localhost]: " domain_name
    [ -z "$domain_name" ] && domain_name="${folder_name}.docker.localhost"
    
    # Network Selection
    networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && networks+=("$line")
    done < <(docker network ls --format "{{.Name}}" | grep -v "bridge\|host\|none")

    # Check if proxy-public exists in the list
    local found_proxy=0
    for n in "${networks[@]}"; do
        if [[ "$n" == "proxy-public" ]]; then
            found_proxy=1
            break
        fi
    done
    
    if [ $found_proxy -eq 0 ]; then
        networks+=("proxy-public (Create new)")
    fi
    networks+=("Manual Input")
    
    interactive_menu "Select Docker Network for Traefik" "${networks[@]}"
    local net_choice=$?
    local selected="${networks[$net_choice]}"
    
    if [[ "$selected" == "Manual Input" ]]; then
         read -p "Enter Docker Network Name: " traefik_network
    elif [[ "$selected" == "proxy-public (Create new)" ]]; then
         traefik_network="proxy-public"
    else
         traefik_network="$selected"
    fi
    
    if [ -d "$folder_name" ]; then
        ask_yes_no "Directory $folder_name already exists. Remove it and continue?"
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}Removing existing directory...${NC}"
            # Use Docker to remove it in case it's owned by root from a previous failed run
            docker run --rm -v "$(pwd):/work" -w /work node:lts-alpine rm -rf "$folder_name"
        else
            echo -e "${RED}Aborted.${NC}"
            return
        fi
    fi

    echo -e "${BLUE}>>> Running create-next-app@latest via Docker...${NC}"
    echo -e "You will be prompted to choose Next.js options."
    
    # Run create-next-app in a container
    # We map the current directory to /work and run the command
    # We use -it to allow interactive prompts
    # We use --user to ensure files are created with the current user's permissions
    # We set HOME=/tmp to avoid permission issues with npm cache in /root
    docker run --rm -it -v "$(pwd):/work" -w /work -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -e HOME=/tmp --user "$(id -u):$(id -g)" node:lts-alpine \
        npx create-next-app@latest "$folder_name"
        
    if [ ! -d "$folder_name" ]; then
            echo -e "${RED}Project generation failed or was cancelled.${NC}"
            return
    fi

    echo -e "${BLUE}>>> Ensuring correct permissions...${NC}"
    # Check if we own the directory and it is writable
    if [ ! -w "$folder_name" ]; then
        echo -e "${YELLOW}Directory is not writable (likely owned by root). Requesting sudo to fix ownership...${NC}"
        # We use sudo to fix the ownership of the folder created by Docker
        sudo chown -R "$(id -u):$(id -g)" "$folder_name"
        sudo chmod -R u+rwX,go+rX "$folder_name"
    else
        echo -e "${GREEN}Permissions look correct.${NC}"
    fi
    
    echo -e "${BLUE}>>> Applying Docker boilerplate configuration...${NC}"
    
    # Copy Docker-related files from template
    cp "$TEMPLATES_DIR/nextjs/Dockerfile" "$folder_name/"
    cp "$TEMPLATES_DIR/nextjs/docker-compose.yml" "$folder_name/"
    cp "$TEMPLATES_DIR/nextjs/.env.example" "$folder_name/"
    cp "$TEMPLATES_DIR/nextjs/README.md" "$folder_name/README-DOCKER.md"
    cp "$TEMPLATES_DIR/nextjs/Makefile" "$folder_name/" 2>/dev/null || true
    cp -r "$TEMPLATES_DIR/nextjs/.github" "$folder_name/" 2>/dev/null || true
    cp "$TEMPLATES_DIR/nextjs/.gitlab-ci.yml" "$folder_name/" 2>/dev/null || true
    
    # Local dev compose (Turbopack is handled by docker-compose.dev.yml command)
    echo -e "${BLUE}>>> Copying docker-compose.dev.yml for local development...${NC}"
    cp "$TEMPLATES_DIR/nextjs/docker-compose.dev.yml" "$folder_name/"
    
    # Ensure proxy-public network exists (in case user skipped Traefik setup)
    # If user specified a custom network, we assume it exists or they will create it.
    # But if it's the default 'proxy-public', we create it if missing.
    if [ "$traefik_network" == "proxy-public" ]; then
        if ! docker network inspect proxy-public >/dev/null 2>&1; then
            echo -e "${BLUE}>>> Creating external network 'proxy-public'...${NC}"
            docker network create proxy-public
        fi
    else
        # Check if custom network exists
        if ! docker network inspect "$traefik_network" >/dev/null 2>&1; then
             echo -e "${YELLOW}Warning: Network '$traefik_network' does not exist. You may need to create it manually.${NC}"
        fi
    fi
    
    cd "$folder_name" || exit

    project_name_sanitized=$(echo "$folder_name" | tr -cd '[:alnum:]-')

    # Create .env locally
    cat > .env <<EOF
PROJECT_NAME=$project_name_sanitized
DOMAIN_NAME=$domain_name
TRAEFIK_NETWORK=$traefik_network
EOF
    
    # Initialize new git repo
    git init -q
    
    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "Next steps:"
    echo -e "  1. cd $folder_name"
    echo -e "  2. git add ."
    echo -e "  3. git commit -m 'Initial commit'"
    echo -e "  4. docker compose up -d --build"
}

# Function to setup React + Vite
setup_vite_react() {
    echo -e "\n${BLUE}>>> Generating New React + Vite Project...${NC}"
    read -p "Enter project name (folder name): " folder_name

    traefik_network="proxy-public"
    echo -e "Enter the domain for your LOCAL environment (e.g., ${folder_name}.docker.localhost)."
    read -p "Local Domain [${folder_name}.docker.localhost]: " domain_name
    [ -z "$domain_name" ] && domain_name="${folder_name}.docker.localhost"

    # Network Selection
    networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && networks+=("$line")
    done < <(docker network ls --format "{{.Name}}" | grep -v "bridge\|host\|none")

    # Check if proxy-public exists in the list
    local found_proxy=0
    for n in "${networks[@]}"; do
        if [[ "$n" == "proxy-public" ]]; then
            found_proxy=1
            break
        fi
    done

    if [ $found_proxy -eq 0 ]; then
        networks+=("proxy-public (Create new)")
    fi
    networks+=("Manual Input")

    interactive_menu "Select Docker Network for Traefik" "${networks[@]}"
    local net_choice=$?
    local selected="${networks[$net_choice]}"

    if [[ "$selected" == "Manual Input" ]]; then
         read -p "Enter Docker Network Name: " traefik_network
    elif [[ "$selected" == "proxy-public (Create new)" ]]; then
         traefik_network="proxy-public"
    else
         traefik_network="$selected"
    fi

    if [ -d "$folder_name" ]; then
        ask_yes_no "Directory $folder_name already exists. Remove it and continue?"
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}Removing existing directory...${NC}"
            docker run --rm -v "$(pwd):/work" -w /work node:lts-alpine rm -rf "$folder_name"
        else
            echo -e "${RED}Aborted.${NC}"
            return
        fi
    fi

    echo -e "${BLUE}>>> Running create-vite@latest via Docker...${NC}"
    docker run --rm -it -v "$(pwd):/work" -w /work -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -e HOME=/tmp --user "$(id -u):$(id -g)" node:lts-alpine \
        sh -lc "npm create --yes vite@latest \"$folder_name\" -- --template react && cd \"$folder_name\" && npm install"

    if [ ! -d "$folder_name" ]; then
        echo -e "${RED}Project generation failed or was cancelled.${NC}"
        return
    fi

    echo -e "${BLUE}>>> Ensuring correct permissions...${NC}"
    if [ ! -w "$folder_name" ]; then
        echo -e "${YELLOW}Directory is not writable (likely owned by root). Requesting sudo to fix ownership...${NC}"
        sudo chown -R "$(id -u):$(id -g)" "$folder_name"
        sudo chmod -R u+rwX,go+rX "$folder_name"
    else
        echo -e "${GREEN}Permissions look correct.${NC}"
    fi

    echo -e "${BLUE}>>> Applying Docker boilerplate configuration...${NC}"
    cp "$TEMPLATES_DIR/vite-react/Dockerfile" "$folder_name/"
    cp "$TEMPLATES_DIR/vite-react/nginx.conf" "$folder_name/"
    cp "$TEMPLATES_DIR/vite-react/docker-compose.yml" "$folder_name/"
    cp "$TEMPLATES_DIR/vite-react/docker-compose.dev.yml" "$folder_name/"
    cp "$TEMPLATES_DIR/vite-react/.env.example" "$folder_name/"
    cp "$TEMPLATES_DIR/vite-react/README.md" "$folder_name/README-DOCKER.md"
    cp "$TEMPLATES_DIR/vite-react/Makefile" "$folder_name/" 2>/dev/null || true
    cp -r "$TEMPLATES_DIR/vite-react/.github" "$folder_name/" 2>/dev/null || true
    cp "$TEMPLATES_DIR/vite-react/.gitlab-ci.yml" "$folder_name/" 2>/dev/null || true

    # Ensure proxy-public network exists
    if [ "$traefik_network" == "proxy-public" ]; then
        if ! docker network inspect proxy-public >/dev/null 2>&1; then
            echo -e "${BLUE}>>> Creating external network 'proxy-public'...${NC}"
            docker network create proxy-public
        fi
    else
        if ! docker network inspect "$traefik_network" >/dev/null 2>&1; then
             echo -e "${YELLOW}Warning: Network '$traefik_network' does not exist. You may need to create it manually.${NC}"
        fi
    fi

    cd "$folder_name" || exit

    project_name_sanitized=$(echo "$folder_name" | tr -cd '[:alnum:]-')
    cat > .env <<EOF
PROJECT_NAME=$project_name_sanitized
DOMAIN_NAME=$domain_name
TRAEFIK_NETWORK=$traefik_network
EOF

    git init -q

    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "Next steps:"
    echo -e "  1. cd $folder_name"
    echo -e "  2. git add ."
    echo -e "  3. git commit -m 'Initial commit'"
    echo -e "  4. docker compose up -d --build"
}

# Function to setup Bot
setup_bot() {
    echo -e "\n${BLUE}>>> Generating New Bot Project...${NC}"
    read -p "Enter project name (folder name): " folder_name
    read -p "Enter Bot Token: " bot_token
    
    traefik_network="proxy-public"
    echo -e "Enter the domain for your LOCAL environment (optional, e.g., ${folder_name}.docker.localhost)."
    read -p "Local Domain: " domain_name
    
    # Network Selection
    networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && networks+=("$line")
    done < <(docker network ls --format "{{.Name}}" | grep -v "bridge\|host\|none")

    # Check if proxy-public exists in the list
    local found_proxy=0
    for n in "${networks[@]}"; do
        if [[ "$n" == "proxy-public" ]]; then
            found_proxy=1
            break
        fi
    done
    
    if [ $found_proxy -eq 0 ]; then
        networks+=("proxy-public (Create new)")
    fi
    networks+=("Manual Input")
    
    interactive_menu "Select Docker Network for Traefik" "${networks[@]}"
    local net_choice=$?
    local selected="${networks[$net_choice]}"
    
    if [[ "$selected" == "Manual Input" ]]; then
         read -p "Enter Docker Network Name: " traefik_network
    elif [[ "$selected" == "proxy-public (Create new)" ]]; then
         traefik_network="proxy-public"
    else
         traefik_network="$selected"
    fi
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Please choose another name.${NC}"
        return
    fi
    
    cp -r "$TEMPLATES_DIR/bot" "$folder_name"
    cd "$folder_name" || exit
    
    project_name_sanitized=$(echo "$folder_name" | tr -cd '[:alnum:]-')

    cat > .env <<EOF
PROJECT_NAME=$project_name_sanitized
BOT_TOKEN=$bot_token
DOMAIN_NAME=$domain_name
TRAEFIK_NETWORK=$traefik_network
TRAEFIK_ENABLE=false
EOF

    # If user provided a domain, assume webhooks via Traefik are desired.
    if [ -n "$domain_name" ]; then
        # Rewrite .env with TRAEFIK_ENABLE=true
        cat > .env <<EOF
PROJECT_NAME=$project_name_sanitized
BOT_TOKEN=$bot_token
DOMAIN_NAME=$domain_name
TRAEFIK_NETWORK=$traefik_network
TRAEFIK_ENABLE=true
EOF
    fi

    # Ensure proxy-public network exists
    if [ "$traefik_network" == "proxy-public" ]; then
        if ! docker network inspect proxy-public >/dev/null 2>&1; then
            echo -e "${BLUE}>>> Creating external network 'proxy-public'...${NC}"
            docker network create proxy-public
        fi
    else
        # Check if custom network exists
        if ! docker network inspect "$traefik_network" >/dev/null 2>&1; then
             echo -e "${YELLOW}Warning: Network '$traefik_network' does not exist. You may need to create it manually.${NC}"
        fi
    fi
    
    # CI/CD is configured via GitHub/GitLab variables; install.sh does not patch CI files.
    
    # Initialize new git repo
    git init -q
    
    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "Next steps:"
    echo -e "  1. cd $folder_name"
    echo -e "  2. git add ."
    echo -e "  3. git commit -m 'Initial commit'"
    echo -e "  4. docker compose up -d --build"
}

# Function to setup Portainer
setup_portainer() {
    echo -e "\n${BLUE}>>> Generating Portainer Project...${NC}"
    read -p "Enter project name (folder name): " folder_name

    traefik_network="proxy-public"
    echo -e "Enter the domain for your LOCAL/PROD environment (e.g., portainer.yourdomain.com or ${folder_name}.docker.localhost)."
    read -p "Domain [${folder_name}.docker.localhost]: " domain_name
    [ -z "$domain_name" ] && domain_name="${folder_name}.docker.localhost"

    # Network Selection
    networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && networks+=("$line")
    done < <(docker network ls --format "{{.Name}}" | grep -v "bridge\|host\|none")

    # Check if proxy-public exists in the list
    local found_proxy=0
    for n in "${networks[@]}"; do
        if [[ "$n" == "proxy-public" ]]; then
            found_proxy=1
            break
        fi
    done

    if [ $found_proxy -eq 0 ]; then
        networks+=("proxy-public (Create new)")
    fi
    networks+=("Manual Input")

    interactive_menu "Select Docker Network for Traefik" "${networks[@]}"
    local net_choice=$?
    local selected="${networks[$net_choice]}"

    if [[ "$selected" == "Manual Input" ]]; then
         read -p "Enter Docker Network Name: " traefik_network
    elif [[ "$selected" == "proxy-public (Create new)" ]]; then
         traefik_network="proxy-public"
    else
         traefik_network="$selected"
    fi

    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Please choose another name.${NC}"
        return
    fi

    cp -r "$TEMPLATES_DIR/portainer" "$folder_name"
    cd "$folder_name" || exit

    project_name_sanitized=$(echo "$folder_name" | tr -cd '[:alnum:]-')

    # Write .env safely (avoid $ expansion in bcrypt hashes)
    : > .env
    printf '%s\n' "PROJECT_NAME=$project_name_sanitized" >> .env
    printf '%s\n' "DOMAIN_NAME=$domain_name" >> .env
    printf '%s\n' "TRAEFIK_NETWORK=$traefik_network" >> .env

    ask_yes_no "Do you want to protect Portainer with Traefik Basic Auth (recommended)?"
    if [ $? -eq 0 ]; then
        read -p "Basic Auth Username: " basic_user
        read -s -p "Basic Auth Password: " basic_pass
        echo ""

        echo -e "${BLUE}>>> Generating password hash...${NC}"
        if ! docker image inspect httpd:alpine &> /dev/null; then
            echo "Pulling helper image..."
            docker pull -q httpd:alpine
        fi

        hash=$(docker run --rm httpd:alpine htpasswd -Bbn "$basic_user" "$basic_pass")
        printf '%s\n' "PORTAINER_BASIC_AUTH_USERS=$hash" >> .env

        # Compose override is auto-loaded by docker compose
        cat > docker-compose.override.yml <<'EOF'
services:
  portainer:
    labels:
      - "traefik.http.routers.${PROJECT_NAME}.middlewares=${PROJECT_NAME}-auth"
      - "traefik.http.middlewares.${PROJECT_NAME}-auth.basicauth.users=${PORTAINER_BASIC_AUTH_USERS?PORTAINER_BASIC_AUTH_USERS must be set}"
EOF
    fi

    # Ensure proxy-public network exists
    if [ "$traefik_network" == "proxy-public" ]; then
        if ! docker network inspect proxy-public >/dev/null 2>&1; then
            echo -e "${BLUE}>>> Creating external network 'proxy-public'...${NC}"
            docker network create proxy-public
        fi
    else
        if ! docker network inspect "$traefik_network" >/dev/null 2>&1; then
             echo -e "${YELLOW}Warning: Network '$traefik_network' does not exist. You may need to create it manually.${NC}"
        fi
    fi

    git init -q

    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "Next steps:"
    echo -e "  1. cd $folder_name"
    echo -e "  2. git add ."
    echo -e "  3. git commit -m 'Initial commit'"
    echo -e "  4. docker compose up -d"
}

# Main Menu
while true; do
    options=("Global Proxy (Traefik)" "Web Project (Next.js)" "React + Vite Project" "Telegram Bot" "Portainer" "Quit")
    interactive_menu "Main Menu" "${options[@]}"
    choice=$?
    
    case $choice in
        0) setup_traefik; break ;;
        1) setup_web; break ;;
        2) setup_vite_react; break ;;
        3) setup_bot; break ;;
        4) setup_portainer; break ;;
        5) echo "Exiting..."; exit 0 ;;
    esac
done
