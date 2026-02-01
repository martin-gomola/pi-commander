#!/bin/bash
################################################################################
# Pi-Commander Installation Script
#
# One-command installation for fresh Ubuntu Server
# Usage: ./install.sh (from cloned repo)
#    or: curl -fsSL https://raw.githubusercontent.com/martin-gomola/pi-commander/main/install.sh | bash
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
║              Pi-Commander Bootstrap Installer                ║
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

# Check if running as root (we don't want that)
if [[ $EUID -eq 0 ]]; then
   error "Please run as your regular user (without sudo). The script will ask for sudo when needed."
fi

# Get system info
OS_VERSION=$(lsb_release -d | cut -f2)
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

info "System detected:"
echo "  OS: $OS_VERSION"
echo "  Hostname: $HOSTNAME"
echo "  IP Address: $IP_ADDRESS"
echo ""

# Install git if not present (only needed for remote curl install)
if ! command -v git &> /dev/null; then
    info "Installing git..."
    sudo apt update && sudo apt install -y git
fi

# Detect if we're already in the repo or need to clone
CURRENT_DIR="$(pwd)"
REPO_DIR="$HOME/pi-commander"

# Check if we're running from within pi-commander directory
if [[ "$CURRENT_DIR" == *"pi-commander"* ]] && [ -f "install-control-plane.sh" ]; then
    log "Running from existing pi-commander directory"
    REPO_DIR="$CURRENT_DIR"
else
    # Clone repository
    if [ -d "$REPO_DIR" ]; then
        warn "Directory $REPO_DIR already exists"
        read -p "Remove and reinstall? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$REPO_DIR"
        else
            error "Installation cancelled"
        fi
    fi
    
    log "Cloning Pi-Commander repository..."
    git clone https://github.com/martin-gomola/pi-commander.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Make scripts executable
chmod +x install-control-plane.sh
chmod +x deploy-auto.sh
chmod +x scripts/*.sh

# Run pre-flight checks
log "Running system compatibility checks..."
echo ""
if ! ./scripts/preflight-check.sh; then
    error "System requirements not met. Please fix issues above and try again."
fi

echo ""
read -p "Pre-flight checks passed. Continue with installation? [Y/n]: " continue_install
if [[ "$continue_install" =~ ^[Nn]$ ]]; then
    error "Installation cancelled by user"
fi

# Run installation
log "Running system installation..."
echo ""
sudo ./install-control-plane.sh

echo ""
log "System installation complete!"
echo ""

# Setup static page from template if needed
if [ ! -f "$REPO_DIR/static/index.html" ] && [ -f "$REPO_DIR/static/index.html.template" ]; then
    info "Setting up static homepage from template..."
    cp "$REPO_DIR/static/index.html.template" "$REPO_DIR/static/index.html"
    log "Static homepage created (customize in static/index.html)"
fi

echo ""

# Offer configuration wizard
info "You can now configure your services:"
echo ""
echo "  1) Run interactive configuration wizard (recommended for first-time users)"
echo "  2) Manually edit configuration files (advanced users)"
echo "  3) Skip configuration (configure later)"
echo ""
read -p "Choose option [1-3]: " config_choice

case $config_choice in
  1)
    log "Starting configuration wizard..."
    echo ""
    ./scripts/config-wizard.sh
    ;;
  2)
    warn "Manual configuration selected"
    info "Edit files in docker/*/.env before deploying"
    ;;
  3)
    warn "Skipping configuration"
    info "You can run './scripts/config-wizard.sh' later"
    ;;
  *)
    warn "Invalid choice, skipping configuration"
    ;;
esac

echo ""

# Prompt to deploy
echo ""
read -p "Deploy core services now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Deploying core services..."
    make deploy-all
    
    echo ""
    log "Installation complete!"
    echo ""
    
    # Show access info
    cat << EOF
${GREEN}╔══════════════════════════════════════════════════════════════╗
║              Pi-Commander Successfully Installed!            ║
╚══════════════════════════════════════════════════════════════╝${NC}

${BLUE}📋 Access Your Services:${NC}
   • Nginx Proxy Manager: ${GREEN}http://${IP_ADDRESS}:81${NC}
     Default login: admin@example.com / changeme
     ${YELLOW}⚠️  Change password immediately!${NC}

   • AdGuard Home:        ${GREEN}http://${IP_ADDRESS}:3001${NC}
     Complete setup wizard on first access

${BLUE}🚀 Next Steps:${NC}
   1. Change default NPM password
   2. Setup AdGuard Home
   3. Edit docker/*/.env files with your tokens/credentials
   4. See docs/first-steps.md for detailed guide

${BLUE}💡 Quick Commands:${NC}
   make status         - Check system status
   make health         - Run health checks
   make lazydocker     - Docker terminal UI
   make help           - Show all commands

${BLUE}📚 Documentation:${NC}
   • README.md - Overview
   • docs/advanced-installation.md - Detailed guide
   • docs/cloudflare-setup.md - Domain setup

${GREEN}Happy self-hosting! 🎉${NC}

EOF
else
    echo ""
    info "Skipping deployment. To deploy later, run:"
    echo "  cd ~/pi-commander"
    echo "  make deploy-all"
fi
