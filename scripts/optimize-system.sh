#!/bin/bash
# Quick System Optimization Script for Pi-Commander
# Applies common performance optimizations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Pi-Commander System Optimization    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo ./optimize-system.sh)${NC}"
    exit 1
fi

# Backup sysctl.conf
echo -e "${YELLOW}[1/6] Backing up /etc/sysctl.conf...${NC}"
cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d-%H%M%S)

# Optimize swap settings
echo -e "${YELLOW}[2/6] Optimizing swap settings...${NC}"
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    sysctl -p > /dev/null
    echo -e "${GREEN}✓ Swap settings optimized${NC}"
else
    echo -e "${GREEN}✓ Swap settings already configured${NC}"
fi

# Configure Docker logging
echo -e "${YELLOW}[3/6] Configuring Docker logging...${NC}"
if [ ! -f /etc/docker/daemon.json ]; then
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    systemctl restart docker
    echo -e "${GREEN}✓ Docker logging configured${NC}"
else
    echo -e "${GREEN}✓ Docker already configured${NC}"
fi

# Create Docker cleanup script
echo -e "${YELLOW}[4/6] Creating Docker cleanup script...${NC}"
cat > /usr/local/bin/docker-cleanup.sh << 'EOF'
#!/bin/bash
echo "=== Docker Cleanup ==="
docker container prune -f
docker image prune -a -f --filter "until=168h"
docker volume prune -f
docker network prune -f
docker builder prune -a -f
echo "=== Cleanup Complete ==="
docker system df
EOF
chmod +x /usr/local/bin/docker-cleanup.sh
echo -e "${GREEN}✓ Cleanup script created${NC}"

# Create health check script
echo -e "${YELLOW}[5/6] Creating health check script...${NC}"
cat > /root/health-check.sh << 'EOF'
#!/bin/bash
echo "=== System Health Check ==="
echo ""
echo "Disk Usage:"
df -h | grep -E '(Filesystem|/dev/)' | grep -v tmpfs
echo ""
echo "Memory Usage:"
free -h
echo ""
echo "Top 5 Memory Consumers:"
ps aux --sort=-%mem | head -6
echo ""
echo "Docker Stats:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""
echo "Load Average:"
uptime
echo ""
echo "=== Complete ==="
EOF
chmod +x /root/health-check.sh
echo -e "${GREEN}✓ Health check script created${NC}"

# Network optimizations
echo -e "${YELLOW}[6/6] Applying network optimizations...${NC}"
if ! grep -q "net.core.rmem_max" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf << 'EOF'

# Network performance tuning
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_tw_reuse=1
EOF
    sysctl -p > /dev/null
    echo -e "${GREEN}✓ Network settings optimized${NC}"
else
    echo -e "${GREEN}✓ Network settings already configured${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Optimization Complete! ✓          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Run health check: /root/health-check.sh"
echo "2. Clean up Docker: /usr/local/bin/docker-cleanup.sh"
echo "3. Monitor: htop or docker stats"
echo ""
echo -e "${YELLOW}Recommended: Add to crontab${NC}"
echo "sudo crontab -e"
echo "Add: 0 3 * * 0 /usr/local/bin/docker-cleanup.sh >> /var/log/docker-cleanup.log 2>&1"
echo ""
echo -e "${BLUE}Full optimization guide: docs/PERFORMANCE-OPTIMIZATION.md${NC}"
