#!/bin/bash

# Configuration
# !!! IMPORTANT: REPLACE THIS WITH YOUR ACTUAL GITHUB REPO URL !!!
REPO_URL="https://github.com/your-username/docker-boilerplate.git"

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

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Function to setup Traefik
setup_traefik() {
    echo -e "\n${BLUE}>>> Setting up Global Proxy (Traefik)...${NC}"
    if [ -d "docker-boilerplate-traefik" ]; then
        cd docker-boilerplate-traefik
        
        read -p "Enter email for Let's Encrypt SSL: " email
        
        cp .env.example .env
        sed -i "s/ACME_EMAIL=.*/ACME_EMAIL=$email/" .env
        
        chmod 600 traefik/acme.json
        
        echo "Starting Traefik..."
        docker-compose up -d
        
        cd ..
        echo -e "${GREEN}Traefik installed successfully!${NC}"
    else
        echo -e "${RED}Error: docker-boilerplate-traefik directory not found.${NC}"
    fi
}

# Function to setup Web
setup_web() {
    echo -e "\n${BLUE}>>> Setting up New Web Project...${NC}"
    read -p "Enter project folder name (e.g., my-website): " folder_name
    read -p "Enter domain name (e.g., example.com): " domain_name
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Skipping.${NC}"
        return
    fi
    
    cp -r docker-boilerplate-web "$folder_name"
    cd "$folder_name"
    
    cp .env.example .env
    sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=$domain_name/" .env
    
    # Update container name to be unique
    sed -i "s/container_name: my-web-project/container_name: $folder_name/" docker-compose.yml
    # Update router names to be unique (remove special chars for router name)
    router_name=$(echo "$folder_name" | tr -cd '[:alnum:]-')
    sed -i "s/traefik.http.routers.my-web/traefik.http.routers.$router_name/g" docker-compose.yml
    sed -i "s/traefik.http.services.my-web/traefik.http.services.$router_name/g" docker-compose.yml
    
    echo "Starting Web Project..."
    docker-compose up -d --build
    
    cd ..
    echo -e "${GREEN}Web project '$folder_name' deployed at https://$domain_name${NC}"
}

# Function to setup Bot
setup_bot() {
    echo -e "\n${BLUE}>>> Setting up New Bot Project...${NC}"
    read -p "Enter project folder name (e.g., my-bot): " folder_name
    read -p "Enter Bot Token: " bot_token
    read -p "Enter Domain (optional, press enter to skip): " domain_name
    
    if [ -d "$folder_name" ]; then
        echo -e "${RED}Directory $folder_name already exists. Skipping.${NC}"
        return
    fi
    
    cp -r docker-boilerplate-bot "$folder_name"
    cd "$folder_name"
    
    cp .env.example .env
    sed -i "s/BOT_TOKEN=.*/BOT_TOKEN=$bot_token/" .env
    
    if [ ! -z "$domain_name" ]; then
        sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=$domain_name/" .env
        # Uncomment Traefik labels if domain is provided
        sed -i 's/# labels:/labels:/' docker-compose.yml
        sed -i 's/#   - "traefik/  - "traefik/g' docker-compose.yml
        
        # Update router names
        router_name=$(echo "$folder_name" | tr -cd '[:alnum:]-')
        sed -i "s/traefik.http.routers.my-bot/traefik.http.routers.$router_name/g" docker-compose.yml
        sed -i "s/traefik.http.services.my-bot/traefik.http.services.$router_name/g" docker-compose.yml
    fi
    
    # Update container name
    sed -i "s/container_name: my-bot-project/container_name: $folder_name/" docker-compose.yml
    
    echo "Starting Bot Project..."
    docker-compose up -d --build
    
    cd ..
    echo -e "${GREEN}Bot project '$folder_name' deployed!${NC}"
}

# Main Menu
PS3='Please enter your choice: '
options=("Install Global Proxy (Traefik)" "Create New Web Project" "Create New Bot Project" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Global Proxy (Traefik)")
            setup_traefik
            ;;
        "Create New Web Project")
            setup_web
            ;;
        "Create New Bot Project")
            setup_bot
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
