#!/bin/bash
# Pre-flight system checks for Pi-Commander
# Validates system requirements before installation

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Pi-Commander Pre-flight Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==================== Operating System ====================
echo -n "OS Compatibility: "
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
    echo -e "${GREEN}✓ $PRETTY_NAME${NC}"
  else
    echo -e "${RED}✗ Unsupported OS: $PRETTY_NAME${NC}"
    echo "  Supported: Ubuntu 22.04+, Debian 11+"
    ((ERRORS++))
  fi
else
  echo -e "${RED}✗ Cannot detect OS${NC}"
  ((ERRORS++))
fi

# ==================== Architecture ====================
echo -n "Architecture: "
ARCH=$(uname -m)
if [[ "$ARCH" =~ ^(x86_64|aarch64|arm64)$ ]]; then
  echo -e "${GREEN}✓ $ARCH${NC}"
else
  echo -e "${YELLOW}⚠ $ARCH (may have limited support)${NC}"
  ((WARNINGS++))
fi

# ==================== RAM ====================
echo -n "RAM: "
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$RAM_GB" -ge 4 ]; then
  echo -e "${GREEN}✓ ${RAM_GB}GB${NC}"
elif [ "$RAM_GB" -ge 2 ]; then
  echo -e "${YELLOW}⚠ ${RAM_GB}GB (4GB+ recommended)${NC}"
  ((WARNINGS++))
else
  echo -e "${RED}✗ ${RAM_GB}GB (minimum 2GB required)${NC}"
  ((ERRORS++))
fi

# ==================== Disk Space ====================
echo -n "Free Disk Space: "
FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_GB" -ge 32 ]; then
  echo -e "${GREEN}✓ ${FREE_GB}GB${NC}"
elif [ "$FREE_GB" -ge 16 ]; then
  echo -e "${YELLOW}⚠ ${FREE_GB}GB (32GB+ recommended)${NC}"
  ((WARNINGS++))
else
  echo -e "${RED}✗ ${FREE_GB}GB (minimum 16GB required)${NC}"
  ((ERRORS++))
fi

# ==================== Docker ====================
echo -n "Docker: "
if command -v docker &> /dev/null; then
  DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
  echo -e "${GREEN}✓ $DOCKER_VERSION${NC}"
else
  echo -e "${YELLOW}⚠ Not installed (will be installed)${NC}"
fi

# ==================== Docker Compose ====================
echo -n "Docker Compose: "
if docker compose version &> /dev/null; then
  COMPOSE_VERSION=$(docker compose version --short)
  echo -e "${GREEN}✓ v$COMPOSE_VERSION${NC}"
else
  echo -e "${YELLOW}⚠ Not installed (will be installed)${NC}"
fi

# ==================== Ports Availability ====================
echo -n "Port 80 (HTTP): "
if ! ss -tuln | grep -q ':80 '; then
  echo -e "${GREEN}✓ Available${NC}"
else
  echo -e "${RED}✗ In use${NC}"
  echo "  Run: sudo ss -tulnp | grep :80"
  ((ERRORS++))
fi

echo -n "Port 443 (HTTPS): "
if ! ss -tuln | grep -q ':443 '; then
  echo -e "${GREEN}✓ Available${NC}"
else
  echo -e "${RED}✗ In use${NC}"
  echo "  Run: sudo ss -tulnp | grep :443"
  ((ERRORS++))
fi

echo -n "Port 53 (DNS): "
if ! ss -tuln | grep -q ':53 '; then
  echo -e "${GREEN}✓ Available${NC}"
else
  echo -e "${YELLOW}⚠ In use (AdGuard may conflict)${NC}"
  echo "  If systemd-resolved is running, see docs/troubleshooting.md"
  ((WARNINGS++))
fi

# ==================== Internet Connectivity ====================
echo -n "Internet: "
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
  echo -e "${GREEN}✓ Connected${NC}"
else
  echo -e "${RED}✗ No connection${NC}"
  ((ERRORS++))
fi

# ==================== DNS Resolution ====================
echo -n "DNS Resolution: "
if host github.com &> /dev/null; then
  echo -e "${GREEN}✓ Working${NC}"
else
  echo -e "${RED}✗ Cannot resolve domains${NC}"
  ((ERRORS++))
fi

# ==================== User Permissions ====================
echo -n "Docker Group: "
if groups | grep -q docker; then
  echo -e "${GREEN}✓ User in docker group${NC}"
else
  echo -e "${YELLOW}⚠ Not in docker group (may need sudo)${NC}"
  ((WARNINGS++))
fi

# ==================== Summary ====================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed! Ready to install.${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warnings (installation can proceed)${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo -e "${RED}✗ $ERRORS errors must be fixed before installation${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
