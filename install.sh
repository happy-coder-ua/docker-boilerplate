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
    read -p "Do you want to install Docker automatically? (y/n): " install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
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

# Function to setup Traefik
setup_traefik() {
    echo -e "\n${BLUE}>>> Generating Global Proxy (Traefik)...${NC}"
    
    TARGET_DIR="global-proxy"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${RED}Directory '$TARGET_DIR' already exists.${NC}"
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
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
    read -p "Do you want to enable the Traefik Dashboard with Basic Auth? (y/n): " enable_dashboard
    if [[ "$enable_dashboard" =~ ^[Yy]$ ]]; then
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
      - \"traefik.http.routers.dashboard.entrypoints=websecure\"
      - \"traefik.http.routers.dashboard.tls.certresolver=myresolver\""

        awk -v labels="$LABELS" '{
            # Match exactly "    networks:" (4 spaces) to avoid matching root "networks:"
            if ($0 == "    networks:" && !found) {
                print labels
                found=1
            }
            print $0
        }' docker-compose.yml > docker-compose.tmp && mv docker-compose.tmp docker-compose.yml
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
    
    echo "Choose generation method:"
    echo "1) Standard Template (Fast, Pre-configured)"
    echo "2) Generate Latest Next.js (npx create-next-app@latest)"
    read -p "Select option (1/2): " web_choice

    read -p "Enter project name (folder name): " folder_name
    read -p "Enter domain name (e.g., example.com): " domain_name
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Please choose another name.${NC}"
        return
    fi

    if [[ "$web_choice" == "2" ]]; then
        echo -e "${BLUE}>>> Running create-next-app@latest via Docker...${NC}"
        echo -e "You will be prompted to choose Next.js options."
        
        # Run create-next-app in a container
        # We map the current directory to /work and run the command
        # We use -it to allow interactive prompts
        docker run --rm -it -v "$(pwd):/work" -w /work node:lts-alpine \
            npx create-next-app@latest "$folder_name"
            
        if [ ! -d "$folder_name" ]; then
             echo -e "${RED}Project generation failed or was cancelled.${NC}"
             return
        fi
        
        echo -e "${BLUE}>>> Applying Docker boilerplate configuration...${NC}"
        
        # Copy Docker-related files from template
        cp "$TEMPLATES_DIR/web/Dockerfile" "$folder_name/"
        cp "$TEMPLATES_DIR/web/docker-compose.yml" "$folder_name/"
        cp "$TEMPLATES_DIR/web/.env.example" "$folder_name/"
        cp -r "$TEMPLATES_DIR/web/.github" "$folder_name/" 2>/dev/null || true
        cp "$TEMPLATES_DIR/web/.gitlab-ci.yml" "$folder_name/" 2>/dev/null || true
        
        # Configure next.config.js/mjs for standalone output (Required for Dockerfile)
        CONFIG_FILE="$folder_name/next.config.js"
        [ -f "$folder_name/next.config.mjs" ] && CONFIG_FILE="$folder_name/next.config.mjs"
        
        if [ -f "$CONFIG_FILE" ]; then
            # Check if output: 'standalone' is already there
            if ! grep -q "standalone" "$CONFIG_FILE"; then
                echo -e "${BLUE}>>> Configuring 'output: standalone' in $CONFIG_FILE...${NC}"
                # Insert output: 'standalone' into the config object
                # This is a bit hacky with sed, but works for standard configs
                # We look for "nextConfig = {" or "const nextConfig = {" and append the line
                sed -i '/nextConfig = {/a \ \ output: "standalone",' "$CONFIG_FILE"
            fi
        fi
        
        cd "$folder_name" || exit
    else
        # Standard Template
        cp -r "$TEMPLATES_DIR/web" "$folder_name"
        cd "$folder_name" || exit
    fi
    
    cp .env.example .env
    sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$domain_name|" .env
    
    # Update container name to be unique
    sed -i "s/container_name: my-web-project/container_name: $folder_name/" docker-compose.yml
    
    # Update router names to be unique (sanitize name)
    router_name=$(echo "$folder_name" | tr -cd '[:alnum:]-')
    sed -i "s/traefik.http.routers.my-web/traefik.http.routers.$router_name/g" docker-compose.yml
    sed -i "s/traefik.http.services.my-web/traefik.http.services.$router_name/g" docker-compose.yml
    
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
    read -p "Enter Domain (optional, press enter to skip): " domain_name
    
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
PS3='Select project type to generate: '
options=("Global Proxy (Traefik)" "Web Project (Next.js)" "Telegram Bot" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Global Proxy (Traefik)")
            setup_traefik
            break
            ;;
        "Web Project (Next.js)")
            setup_web
            break
            ;;
        "Telegram Bot")
            setup_bot
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
