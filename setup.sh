#!/bin/bash
################################################################################
# Pi-Commander Setup Script
# VERSION: 2026-02-01-v13
#
# Sets up prerequisites for deploying services
# Usage: curl -fsSL https://raw.githubusercontent.com/martin-gomola/pi-commander/main/setup.sh | bash
################################################################################

set -e

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[✓] $1${NC}"; }
info() { echo -e "${BLUE}[i] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# Banner
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                   Pi-Commander Setup                         ║
║                                                              ║
║     Transform your old laptop into a powerful homelab       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF

info "Starting installation..."
echo ""

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    error "This script requires Ubuntu/Debian-based Linux"
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "Please run as your regular user (without sudo). The script will ask for sudo when needed."
fi

# Show system info
info "System: $(lsb_release -ds 2>/dev/null || echo 'Linux')"
info "Host: $(hostname)"
echo ""

################################################################################
# Install Docker
################################################################################

info "Installing Docker and prerequisites..."
echo ""

# Update package list
log "Updating package list..."
sudo apt update -qq

# Install prerequisites
log "Installing prerequisites..."
sudo apt install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    git \
    make \
    nano \
    net-tools

# Install Docker if not present
if command -v docker &> /dev/null; then
    log "Docker already installed: $(docker --version)"
else
    log "Installing Docker..."
    
    # Add Docker GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update -qq
    sudo apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log "Docker installed: $(docker --version)"
fi

# Add user to docker group
if groups $USER | grep -q docker; then
    log "User already in docker group"
else
    log "Adding user to docker group..."
    sudo usermod -aG docker $USER
    warn "You'll need to log out and back in for docker group to take effect"
fi

# Create directories
log "Creating directory structure..."
sudo mkdir -p /srv/docker
sudo mkdir -p /srv/backups
sudo chown -R $USER:$USER /srv/docker
sudo chown -R $USER:$USER /srv/backups

echo ""
log "Docker installation complete!"
echo ""

################################################################################
# Install Docker Tools
################################################################################

info "Installing Docker management tools..."
echo ""

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        LAZYDOCKER_ARCH="x86_64"
        ;;
    aarch64|arm64)
        LAZYDOCKER_ARCH="arm64"
        ;;
    armv7l)
        LAZYDOCKER_ARCH="armv7"
        ;;
    *)
        warn "Unsupported architecture for lazydocker: $ARCH"
        LAZYDOCKER_ARCH=""
        ;;
esac

# Install lazydocker
if command -v lazydocker &> /dev/null; then
    log "lazydocker already installed"
elif [ -n "$LAZYDOCKER_ARCH" ]; then
    log "Installing lazydocker..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LAZYDOCKER_ARCH}.tar.gz"
    tar xf lazydocker.tar.gz lazydocker
    sudo install lazydocker /usr/local/bin
    rm lazydocker.tar.gz lazydocker
    log "lazydocker installed"
fi

# Install dockcheck
if command -v dockcheck.sh &> /dev/null; then
    log "dockcheck already installed"
else
    log "Installing dockcheck..."
    curl -fsSL https://raw.githubusercontent.com/mag37/dockcheck/main/dockcheck.sh -o dockcheck.sh
    chmod +x dockcheck.sh
    sudo mv dockcheck.sh /usr/local/bin/
    log "dockcheck installed"
fi

echo ""
log "Docker tools installation complete!"
echo ""

################################################################################
# Clone Repository
################################################################################

REPO_DIR="$HOME/pi-commander"

if [ -d "$REPO_DIR" ]; then
    warn "Directory $REPO_DIR already exists"
    info "Pulling latest changes..."
    cd "$REPO_DIR"
    git pull -q
else
    log "Cloning Pi-Commander repository..."
    git clone -q https://github.com/martin-gomola/pi-commander.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Make scripts executable
chmod +x deploy-auto.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

echo ""
log "Installation complete!"
echo ""

################################################################################
# Next Steps
################################################################################

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Pi-Commander Successfully Installed!            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Activate docker group (choose one):${NC}"
echo ""
echo -e "   ${GREEN}Option 1 (Quick):${NC}   newgrp docker"
echo -e "   ${GREEN}Option 2:${NC}         Exit SSH and reconnect"
echo -e "   ${GREEN}Option 3:${NC}         sudo reboot"
echo ""
echo -e "${BLUE}📋 Configure Services:${NC}"
echo ""
echo -e "   ${GREEN}cd ~/pi-commander/docker/nginx-proxy-manager${NC}"
echo -e "   ${GREEN}cp .env.example .env && nano .env${NC}    ${BLUE}# Set your email & password${NC}"
echo ""
echo -e "   ${GREEN}cd ~/pi-commander/docker/adguard${NC}"
echo -e "   ${GREEN}cp .env.example .env && nano .env${NC}    ${BLUE}# Configure DNS & ad-blocking${NC}"
echo ""
echo -e "   ${GREEN}cd ~/pi-commander/docker/twingate${NC}"
echo -e "   ${GREEN}cp .env.example .env && nano .env${NC}    ${BLUE}# Configure VPN (optional)${NC}"
echo ""
echo -e "   ${GREEN}cd ~/pi-commander/docker/cloudflare-ddns${NC}"
echo -e "   ${GREEN}cp .env.example .env && nano .env${NC}    ${BLUE}# OR use duckdns instead${NC}"
echo ""
echo -e "   ${BLUE}# Then deploy all services:${NC}"
echo -e "   ${GREEN}cd ~/pi-commander && make deploy-all${NC}"
echo ""
echo ""
echo -e "${BLUE}💡 Useful Commands:${NC}"
echo ""
echo -e "   ${GREEN}make help${NC}             - Show all available commands"
echo -e "   ${GREEN}make status${NC}           - Check system status"
echo -e "   ${GREEN}lazydocker${NC}            - Docker terminal UI"
echo -e "   ${GREEN}dockcheck.sh${NC}          - Check for container updates"
echo ""
echo -e "${GREEN}Happy self-hosting! 🎉${NC}"
echo ""
