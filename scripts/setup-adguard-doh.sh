#!/bin/bash
################################################################################
# AdGuard DoH Certificate Setup Script
#
# Sets up self-signed SSL certificate for AdGuard Home DoH
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== AdGuard DoH Certificate Setup ===${NC}"
echo ""

# Create certificates directory
echo -e "${YELLOW}Creating certificates directory...${NC}"
sudo mkdir -p /srv/docker/adguard/certs
cd /srv/docker/adguard/certs

# Generate self-signed certificate
echo ""
echo -e "${YELLOW}Generating self-signed certificate (valid for 10 years)...${NC}"
sudo openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
  -nodes \
  -keyout adguard.key \
  -out adguard.crt \
  -subj "/CN=adguard.home.local" \
  -addext "subjectAltName=DNS:adguard.home.local,DNS:*.home.local,IP:192.168.1.190"

# Set correct permissions
echo ""
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R 1000:1000 /srv/docker/adguard/certs
sudo chmod 644 /srv/docker/adguard/certs/adguard.crt
sudo chmod 600 /srv/docker/adguard/certs/adguard.key

# Verify certificates
echo ""
echo -e "${GREEN}✓ Certificates created:${NC}"
ls -lh /srv/docker/adguard/certs/

# Pull latest code
echo ""
echo -e "${YELLOW}Pulling latest pi-commander code...${NC}"
cd ~/pi-commander
git pull origin main

# Restart AdGuard
echo ""
echo -e "${YELLOW}Restarting AdGuard with new configuration...${NC}"
cd ~/pi-commander/docker/adguard-twingate
docker-compose down
docker-compose up -d

# Wait for startup
echo ""
echo -e "${YELLOW}Waiting for AdGuard to start...${NC}"
sleep 5

# Check status
echo ""
echo -e "${GREEN}✓ AdGuard status:${NC}"
docker ps | grep adguard-home

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete!                                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Go to AdGuard UI: http://192.168.1.190:3001"
echo "2. Settings → Encryption"
echo "3. Set certificate path: ${YELLOW}/opt/adguardhome/certs/adguard.crt${NC}"
echo "4. Set private key path: ${YELLOW}/opt/adguardhome/certs/adguard.key${NC}"
echo "5. Click '${GREEN}Save configuration${NC}'"
echo ""
echo -e "${BLUE}Test DoH:${NC}"
echo "curl -k 'https://localhost/dns-query?name=google.com&type=A' -H 'accept: application/dns-json'"
echo ""
