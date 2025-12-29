#!/bin/bash

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

echo -e "${BLUE}=== Docker Project Generator ===${NC}"
echo -e "This tool will generate a standalone project in the CURRENT directory."
echo -e "Current directory: $(pwd)"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Function to setup Traefik
setup_traefik() {
    echo -e "\n${BLUE}>>> Generating Global Proxy (Traefik)...${NC}"
    
    TARGET_DIR="global-proxy"
    if [ -d "$TARGET_DIR" ]; then
        read -p "Directory '$TARGET_DIR' already exists. Enter new name (or Ctrl+C to cancel): " TARGET_DIR
    fi

    cp -r "$TEMPLATES_DIR/traefik" "$TARGET_DIR"
    cd "$TARGET_DIR" || exit
    
    read -p "Enter email for Let's Encrypt SSL: " email
    
    cp .env.example .env
    # Use | as delimiter to avoid issues with special chars in email
    sed -i "s|ACME_EMAIL=.*|ACME_EMAIL=$email|" .env
    
    chmod 600 traefik/acme.json
    
    echo -e "${GREEN}Success!${NC}"
    echo -e "Created standalone project in: ${BLUE}$(pwd)${NC}"
    echo -e "To start it:"
    echo -e "  cd $TARGET_DIR"
    echo -e "  docker-compose up -d"
}

# Function to setup Web
setup_web() {
    echo -e "\n${BLUE}>>> Generating New Web Project...${NC}"
    read -p "Enter project name (folder name): " folder_name
    read -p "Enter domain name (e.g., example.com): " domain_name
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Please choose another name.${NC}"
        return
    fi
    
    cp -r "$TEMPLATES_DIR/web" "$folder_name"
    cd "$folder_name" || exit
    
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
    echo -e "  4. docker-compose up -d --build"
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
    echo -e "  4. docker-compose up -d --build"
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
