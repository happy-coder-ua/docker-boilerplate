#!/bin/bash

# Version: 1.1.0

# Configuration
# !!! IMPORTANT: REPLACE THIS WITH YOUR ACTUAL GITHUB REPO URL !!!
REPO_URL="https://github.com/happy-coder-ua/docker-boilerplate.git"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Interactive Environment Selection
ENV_TYPE="local"
ask_environment() {
    local options=("Local Computer (Development)" "VPS Server (Production)")
    interactive_menu "Docker Project Generator v1.2.0" "${options[@]}"
    local choice=$?

    if [ $choice -eq 0 ]; then
        ENV_TYPE="local"
        echo -e "${GREEN}>>> Mode: Local Development${NC}"
    else
        ENV_TYPE="vps"
        echo -e "${RED}>>> Mode: VPS Production${NC}"
    fi
    echo ""
}

ask_environment

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
    
    cp .env.example .env
    # Use | as delimiter to avoid issues with special chars in email
    sed -i "s|ACME_EMAIL=.*|ACME_EMAIL=$email|" .env
    
    # Also update email in traefik.yml
    sed -i "s|EMAIL_PLACEHOLDER|$email|" traefik/traefik.yml
    
    chmod 600 traefik/acme.json

    # Dashboard Setup
    ask_yes_no "Do you want to enable the Traefik Dashboard with Basic Auth?"
    if [ $? -eq 0 ]; then
        read -p "Enter Dashboard Domain (e.g. traefik.yourdomain.com): " dashboard_domain
        read -p "Enter Dashboard Username: " dashboard_user
        read -s -p "Enter Dashboard Password: " dashboard_pass
        echo ""
        
        echo -e "${BLUE}>>> Generating password hash...${NC}"
        if ! docker image inspect httpd:alpine &> /dev/null; then
             echo "Pulling helper image..."
             docker pull -q httpd:alpine
        fi
        
        # Generate hash: user:$apr1$xyz...
        hash=$(docker run --rm httpd:alpine htpasswd -Bbn "$dashboard_user" "$dashboard_pass")
        
        # Escape $ to $$ for docker-compose
        docker_compose_hash=$(echo "$hash" | sed 's/\$/\$\$/g')
        
        # Disable insecure mode
        sed -i 's/insecure: true/insecure: false/' traefik/traefik.yml
        
        # Remove port 8080
        sed -i '/- "8080:8080"/d' docker-compose.yml
        
        # Add labels using awk to insert before '    networks:'
        LABELS="    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.dashboard.rule=Host(\`$dashboard_domain\`)\"
      - \"traefik.http.routers.dashboard.service=api@internal\"
      - \"traefik.http.routers.dashboard.middlewares=auth,dashboard-redirect\"
      - \"traefik.http.middlewares.auth.basicauth.users=$docker_compose_hash\"
      - \"traefik.http.middlewares.dashboard-redirect.redirectregex.regex=^https?://[^/]+/\$\$\"
      - \"traefik.http.middlewares.dashboard-redirect.redirectregex.replacement=https://$dashboard_domain/dashboard/\"
      - \"traefik.http.middlewares.dashboard-redirect.redirectregex.permanent=true\"
      - \"traefik.http.routers.dashboard.entrypoints=https\"
      - \"traefik.http.routers.dashboard.tls.certresolver=myresolver\""

        awk -v labels="$LABELS" '{
            # Match exactly "    networks:" (4 spaces) to avoid matching root "networks:"
            if ($0 == "    networks:" && !found) {
                print labels
                found=1
            }
            print $0
        }' docker-compose.yml > docker-compose.tmp && mv docker-compose.tmp docker-compose.yml
        
        enable_dashboard="y" # Set for later use
    else
        enable_dashboard="n"
    fi
    
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
    if [ "$ENV_TYPE" == "local" ]; then
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
    else
        read -p "Enter the PRODUCTION domain (e.g., example.com): " domain_name
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
    docker run --rm -it -v "$(pwd):/work" -w /work -e HOME=/tmp --user "$(id -u):$(id -g)" node:lts-alpine \
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
    cp "$TEMPLATES_DIR/web/Dockerfile" "$folder_name/"
    cp "$TEMPLATES_DIR/web/docker-compose.yml" "$folder_name/"
    cp "$TEMPLATES_DIR/web/.env.example" "$folder_name/"
    cp "$TEMPLATES_DIR/web/README.md" "$folder_name/README-DOCKER.md"
    cp -r "$TEMPLATES_DIR/web/.github" "$folder_name/" 2>/dev/null || true
    cp "$TEMPLATES_DIR/web/.gitlab-ci.yml" "$folder_name/" 2>/dev/null || true
    
    # Configure next.config.js/mjs/ts for standalone output (Required for Dockerfile)
    CONFIG_FILE=""
    if [ -f "$folder_name/next.config.js" ]; then CONFIG_FILE="$folder_name/next.config.js"; fi
    if [ -f "$folder_name/next.config.mjs" ]; then CONFIG_FILE="$folder_name/next.config.mjs"; fi
    if [ -f "$folder_name/next.config.ts" ]; then CONFIG_FILE="$folder_name/next.config.ts"; fi
    
    if [ -n "$CONFIG_FILE" ]; then
        # Check if output: 'standalone' is already there
        if ! grep -q "standalone" "$CONFIG_FILE"; then
            echo -e "${BLUE}>>> Configuring 'output: standalone' in $CONFIG_FILE...${NC}"
            # Insert output: 'standalone' into the config object
            # We look for "nextConfig = {" or "const nextConfig: NextConfig = {" and append the line
            # The regex matches: nextConfig followed by any chars, then =, then any chars, then {
            sed -i '/nextConfig.*=.*{/a \ \ output: "standalone",' "$CONFIG_FILE"
        fi
    else
        echo -e "${YELLOW}Warning: Could not find next.config.{js,mjs,ts}. Please manually add 'output: \"standalone\"' to your config.${NC}"
    fi
    
    # Enable Turbopack for local development
    if [ "$ENV_TYPE" == "local" ]; then
        if [ -f "$folder_name/package.json" ]; then
            echo -e "${BLUE}>>> Enabling Turbopack for local development...${NC}"
            sed -i 's/"dev": "next dev"/"dev": "next dev --turbo"/' "$folder_name/package.json"
        fi
        
        # Copy docker-compose.dev.yml for local development
        echo -e "${BLUE}>>> Copying docker-compose.dev.yml for local development...${NC}"
        cp "$TEMPLATES_DIR/web/docker-compose.dev.yml" "$folder_name/"
    fi
    
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
    
    cp .env.example .env
    sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$domain_name|" .env
    
    # Update network name in docker-compose files
    if [ "$traefik_network" != "proxy-public" ]; then
        sed -i "s/proxy-public/$traefik_network/g" docker-compose.yml
        if [ -f "docker-compose.dev.yml" ]; then
            sed -i "s/proxy-public/$traefik_network/g" docker-compose.dev.yml
        fi
    fi
    
    # Update container name to be unique
    sed -i "s/container_name: my-web-project/container_name: $folder_name/" docker-compose.yml
    if [ -f "docker-compose.dev.yml" ]; then
        sed -i "s/container_name: my-web-project-dev/container_name: ${folder_name}-dev/" docker-compose.dev.yml
    fi
    
    # Update router names to be unique (sanitize name)
    router_name=$(echo "$folder_name" | tr -cd '[:alnum:]-')
    sed -i "s/traefik.http.routers.my-web/traefik.http.routers.$router_name/g" docker-compose.yml
    sed -i "s/traefik.http.services.my-web/traefik.http.services.$router_name/g" docker-compose.yml
    
    # Update CI/CD paths
    echo -e "\n${BLUE}>>> CI/CD Configuration${NC}"
    
    if [ "$ENV_TYPE" == "local" ]; then
        echo "Since you are running locally, we need to know where the project will be on your VPS."
        read -p "Enter the absolute path on VPS (e.g., /root/projects/$folder_name): " remote_path
        
        if [ -z "$remote_path" ]; then
            remote_path="/root/projects/$folder_name"
            echo -e "Using default: $remote_path"
        fi
        PROJECT_PATH="$remote_path"
    else
        # On VPS, the current path is the project path
        PROJECT_PATH=$(pwd)
        echo -e "Using current path for CI/CD: $PROJECT_PATH"
    fi
    
    # Update GitHub Actions
    if [ -f ".github/workflows/main.yml" ]; then
        sed -i "s|cd /path/to/your/web-project|cd $PROJECT_PATH|" .github/workflows/main.yml
    fi
    
    # Update GitLab CI
    if [ -f ".gitlab-ci.yml" ]; then
        sed -i "s|cd /path/to/your/web-project|cd $PROJECT_PATH|" .gitlab-ci.yml
    fi
    
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

# Function to setup Bot
setup_bot() {
    echo -e "\n${BLUE}>>> Generating New Bot Project...${NC}"
    read -p "Enter project name (folder name): " folder_name
    read -p "Enter Bot Token: " bot_token
    
    traefik_network="proxy-public"
    if [ "$ENV_TYPE" == "local" ]; then
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
    else
        read -p "Enter the PRODUCTION domain (optional, e.g., bot.example.com): " domain_name
    fi
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Please choose another name.${NC}"
        return
    fi
    
    cp -r "$TEMPLATES_DIR/bot" "$folder_name"
    cd "$folder_name" || exit
    
    cp .env.example .env
    sed -i "s|BOT_TOKEN=.*|BOT_TOKEN=$bot_token|" .env
    
    if [ ! -z "$domain_name" ]; then
        sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$domain_name|" .env
        # Uncomment Traefik labels
        sed -i 's/# labels:/labels:/' docker-compose.yml
        sed -i 's/#   - "traefik/  - "traefik/g' docker-compose.yml
        
        # Update router names
        router_name=$(echo "$folder_name" | tr -cd '[:alnum:]-')
        sed -i "s/traefik.http.routers.my-bot/traefik.http.routers.$router_name/g" docker-compose.yml
        sed -i "s/traefik.http.services.my-bot/traefik.http.services.$router_name/g" docker-compose.yml
    fi
    
    # Update container name
    sed -i "s/container_name: my-bot-project/container_name: $folder_name/" docker-compose.yml
    
    # Update network name in docker-compose files
    if [ "$traefik_network" != "proxy-public" ]; then
        sed -i "s/proxy-public/$traefik_network/g" docker-compose.yml
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
    
    # Update CI/CD paths
    echo -e "\n${BLUE}>>> CI/CD Configuration${NC}"
    
    if [ "$ENV_TYPE" == "local" ]; then
        echo "Since you are running locally, we need to know where the project will be on your VPS."
        read -p "Enter the absolute path on VPS (e.g., /root/projects/$folder_name): " remote_path
        if [ -z "$remote_path" ]; then
            remote_path="/root/projects/$folder_name"
            echo -e "Using default: $remote_path"
        fi
        PROJECT_PATH="$remote_path"
    else
        PROJECT_PATH=$(pwd)
        echo -e "Using current path for CI/CD: $PROJECT_PATH"
    fi
    
    # Update GitHub Actions
    if [ -f ".github/workflows/main.yml" ]; then
        sed -i "s|cd /path/to/your/bot-project|cd $PROJECT_PATH|" .github/workflows/main.yml
    fi
    
    # Update GitLab CI
    if [ -f ".gitlab-ci.yml" ]; then
        sed -i "s|cd /path/to/your/bot-project|cd $PROJECT_PATH|" .gitlab-ci.yml
    fi
    
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

# Main Menu
while true; do
    options=("Global Proxy (Traefik)" "Web Project (Next.js)" "Telegram Bot" "Quit")
    interactive_menu "Main Menu" "${options[@]}"
    choice=$?
    
    case $choice in
        0) setup_traefik; break ;;
        1) setup_web; break ;;
        2) setup_bot; break ;;
        3) echo "Exiting..."; exit 0 ;;
    esac
done
