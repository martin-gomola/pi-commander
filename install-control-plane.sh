#!/bin/bash

################################################################################
# Pi-Commander Installation Script
#
# Purpose: Install Docker and setup directory structure
# Usage: sudo ./install-control-plane.sh
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

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   error "This script must be run with sudo"
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo "~$ACTUAL_USER")

info "Pi-Commander Installation"
info "Installing as user: $ACTUAL_USER"
echo ""

# Pre-flight checks
preflight_checks() {
    local errors=0
    local warnings=0
    
    info "Running pre-flight checks..."
    echo ""
    
    # Check OS
    if ! command -v apt &> /dev/null; then
        error "This script requires a Debian/Ubuntu-based system"
    fi
    log "✓ OS: Debian/Ubuntu detected"
    
    # Check RAM
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    local ram_gb=$((ram_mb / 1024))
    if [ "$ram_gb" -lt 4 ]; then
        warn "RAM: ${ram_gb}GB (4GB+ recommended for smooth operation)"
        warnings=$((warnings + 1))
    else
        log "✓ RAM: ${ram_gb}GB"
    fi
    
    # Check disk space
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$disk_gb" -lt 32 ]; then
        error "Disk space: ${disk_gb}GB available (32GB+ required)"
        errors=$((errors + 1))
    else
        log "✓ Disk space: ${disk_gb}GB available"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        error "No internet connection detected"
        errors=$((errors + 1))
    else
        log "✓ Internet connectivity"
    fi
    
    # Check if ports are available
    local ports_in_use=()
    for port in 80 81 443 53; do
        if ss -tuln | grep -q ":${port} "; then
            ports_in_use+=($port)
        fi
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        warn "Ports in use: ${ports_in_use[*]} (may conflict with services)"
        info "You may need to stop conflicting services (e.g., apache2, systemd-resolved)"
        warnings=$((warnings + 1))
    else
        log "✓ Required ports available"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        warn "CPU: ${cpu_cores} core (2+ recommended)"
        warnings=$((warnings + 1))
    else
        log "✓ CPU: ${cpu_cores} cores"
    fi
    
    # Check architecture
    local arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        warn "Architecture: $arch (x86_64 recommended, may have compatibility issues)"
        warnings=$((warnings + 1))
    else
        log "✓ Architecture: $arch"
    fi
    
    echo ""
    if [ $errors -gt 0 ]; then
        error "Pre-flight checks failed with $errors error(s). Cannot continue."
    fi
    
    if [ $warnings -gt 0 ]; then
        warn "$warnings warning(s) detected. Installation can continue but may have issues."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Installation cancelled by user"
        fi
    fi
    
    log "Pre-flight checks passed"
    echo ""
}

preflight_checks

log "Step 1: Updating system..."
apt update && apt upgrade -y

log "Step 2: Installing prerequisites..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    git \
    nano \
    htop \
    net-tools

log "Step 3: Installing Docker..."

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    warn "Docker is already installed"
    docker --version
else
    # Add Docker GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log "Docker installed successfully"
fi

log "Step 4: Installing Docker Compose..."

# Check if docker-compose is already installed
if command -v docker-compose &> /dev/null; then
    warn "Docker Compose is already installed"
    docker-compose --version
else
    # Install Docker Compose standalone
    LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    log "Docker Compose installed successfully"
fi

log "Step 5: Adding user to docker group..."
usermod -aG docker "$ACTUAL_USER"

log "Step 6: Enabling Docker service..."
systemctl enable docker
systemctl start docker

log "Step 7: Creating directory structure..."

# Create main docker directory
mkdir -p /srv/docker
mkdir -p /srv/backups

# Create core service directories
declare -a core_services=(
    "nginx-proxy-manager"
    "dns-server"
)

for service in "${core_services[@]}"; do
    mkdir -p "/srv/docker/${service}"
    log "Created /srv/docker/$service"
done

# Set ownership
chown -R "$ACTUAL_USER:$ACTUAL_USER" /srv/docker
chown -R "$ACTUAL_USER:$ACTUAL_USER" /srv/backups

log "Step 8: Installing lazydocker..."

# Install lazydocker - terminal UI for Docker
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | jq -r .tag_name)
if [ -n "$LAZYDOCKER_VERSION" ] && [ "$LAZYDOCKER_VERSION" != "null" ]; then
    curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
    install /tmp/lazydocker /usr/local/bin/
    rm -f /tmp/lazydocker /tmp/lazydocker.tar.gz
    log "lazydocker ${LAZYDOCKER_VERSION} installed successfully"
else
    warn "Could not determine lazydocker version, skipping installation"
fi

log "Step 9: Installing dockcheck..."

# Install dockcheck - container update checker
curl -Lo /usr/local/bin/dockcheck.sh https://raw.githubusercontent.com/mag37/dockcheck/main/dockcheck.sh
chmod +x /usr/local/bin/dockcheck.sh
log "dockcheck installed successfully"

log "Step 10: Creating Docker networks..."

# Wait for Docker daemon to be fully ready
sleep 3

# Create networks if they don't exist
if ! docker network ls | grep -q "proxy_network"; then
    docker network create proxy_network || warn "Could not create proxy_network (may already exist)"
fi

if ! docker network ls | grep -q "internal_network"; then
    docker network create internal_network || warn "Could not create internal_network (may already exist)"
fi

# Show completion message
cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════════╗
║          Pi-Commander Installation Complete!                 ║
╚══════════════════════════════════════════════════════════════╝${NC}

${BLUE}📋 What was installed:${NC}
   ✓ Docker Engine
   ✓ Docker Compose
   ✓ lazydocker (terminal UI for Docker)
   ✓ dockcheck (container update checker)
   ✓ Directory structure (/srv/docker, /srv/backups)
   ✓ Docker networks (proxy_network, internal_network)
   ✓ User '$ACTUAL_USER' added to docker group

${BLUE}📁 Directories created:${NC}
   • /srv/docker/          - Docker volume data
   • /srv/backups/         - Backup storage

${YELLOW}⚠️  IMPORTANT: Log out and back in for docker group to take effect${NC}

${BLUE}🚀 Next steps:${NC}
   1. Log out and back in (or run: newgrp docker)
   2. cd ~/pi-commander
   3. Setup .env files:
      cd docker/nginx-proxy-manager && cp .env.example .env && cd ../..
      cd docker/adguard && cp .env.example .env && cd ../..
      cd docker/twingate && cp .env.example .env && cd ../..
      cd docker/cloudflare-ddns && cp .env.example .env && cd ../..
   4. Edit each .env file with your credentials
   5. make deploy-all     (deploy all services)

${BLUE}📖 Documentation:${NC}
   • README.md                          - Overview
   • docs/QUICK-REFERENCE.md           - Quick commands
   • docs/ZOTAC-FRESH-INSTALL.md       - Detailed setup guide

${BLUE}🛠️  Quick commands:${NC}
   make update         - Update & deploy changes
   make status         - Check status
   make health         - Health checks
   make lazydocker     - Launch Docker terminal UI
   make check-updates  - Check for container updates
   make help           - Show all commands

${GREEN}Installation complete! Happy self-hosting! 🚀${NC}

EOF
