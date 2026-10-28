#!/usr/bin/env bash
################################################################################
# Pi-Commander Diagnostics Script
#
# Gathers system information for troubleshooting
# Usage: ./scripts/diagnostics.sh > diagnostics.txt
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/pi-commander.sh
source "$SCRIPT_DIR/lib/pi-commander.sh"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}[i] $1${NC}"; }

cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║           Pi-Commander Diagnostics Report                    ║
╚══════════════════════════════════════════════════════════════╝

EOF

echo "Generated: $(date)"
echo ""

info "System Information"
echo "=================="
uname -a
echo ""
if command -v lsb_release &> /dev/null; then
    lsb_release -a 2>/dev/null
fi
echo ""

info "Hardware Resources"
echo "=================="
echo "CPU:"
lscpu | grep -E "Model name|CPU\(s\):|Thread|Core"
echo ""
echo "Memory:"
free -h
echo ""
echo "Disk:"
df -h | grep -E "Filesystem|/dev/"
echo ""

info "Network"
echo "======="
echo "IP Addresses:"
hostname -I
echo ""
echo "Hostname: $(hostname)"
echo ""
echo "Listening Ports:"
ss -tulpn 2>/dev/null | grep -E ":(80|81|443|53|3001)" || echo "No services listening on standard ports"
echo ""

info "Docker Status"
echo "============="
if command -v docker &> /dev/null; then
    docker --version
    echo ""
    docker-compose --version 2>/dev/null || docker compose version 2>/dev/null
    echo ""
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    echo ""
    echo "All Containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}"
    echo ""
    echo "Docker Disk Usage:"
    docker system df
else
    echo "Docker not installed"
fi
echo ""

info "Pi-Commander Status"
echo "==================="
if [ -d ~/pi-commander ]; then
    cd ~/pi-commander
    echo "Repository: ~/pi-commander"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Configuration:"
    pc_list_config_status
    echo ""
else
    echo "Pi-Commander not found in ~/pi-commander"
fi

info "Recent Container Errors"
echo "======================="
if command -v docker &> /dev/null; then
    pc_list_container_errors
else
    echo "Docker not installed"
fi
echo ""

info "Firewall Status"
echo "==============="
if command -v ufw &> /dev/null; then
    sudo ufw status 2>/dev/null || echo "UFW not configured"
else
    echo "UFW not installed"
fi
echo ""

info "System Load"
echo "==========="
uptime
echo ""
echo "Top Memory Consumers:"
ps aux --sort=-%mem | head -6
echo ""

cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                   End of Diagnostics                         ║
╚══════════════════════════════════════════════════════════════╝

Save this output and share it when asking for help:
  ./scripts/diagnostics.sh > diagnostics.txt

EOF
