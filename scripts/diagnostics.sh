#!/bin/bash
################################################################################
# Pi-Commander Diagnostics Script
#
# Gathers system information for troubleshooting
# Usage: ./scripts/diagnostics.sh > diagnostics.txt
################################################################################

set -e

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
    [ -f docker/nginx-proxy-manager/.env ] && echo "✓ nginx-proxy-manager/.env exists" || echo "✗ nginx-proxy-manager/.env missing"
    [ -f docker/adguard/.env ] && echo "✓ adguard/.env exists" || echo "✗ adguard/.env missing"
    [ -f docker/twingate/.env ] && echo "✓ twingate/.env exists" || echo "✗ twingate/.env missing"
    [ -f docker/cloudflare-ddns/.env ] && echo "✓ cloudflare-ddns/.env exists" || echo "✗ cloudflare-ddns/.env missing"
    echo ""
else
    echo "Pi-Commander not found in ~/pi-commander"
fi

info "Recent Container Errors"
echo "======================="
if command -v docker &> /dev/null; then
    for container in nginx-proxy-manager adguard-home twingate-connector cloudflare-ddns; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            echo ""
            echo "=== $container ==="
            docker logs $container --tail 20 2>&1 | grep -iE "error|fail|fatal" || echo "No errors found"
        fi
    done
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
