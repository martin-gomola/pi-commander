# Advanced Installation Guide

**For experts who want to understand the internals or do manual installation.**

**Most users should use:** [Quick Start](../README.md#quick-start-fresh-ubuntu-server) (one command)

---

## Architecture Overview

### Service Stack

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
                    ┌─────▼─────┐
                    │ Cloudflare│
                    │   CDN     │
                    └─────┬─────┘
                          │
              ┌───────────┼───────────┐
              │     80/443│           │
         ┌────▼────┐      │      ┌────▼──────┐
         │ Router  │      │      │ Twingate  │
         │   NAT   │      │      │  Network  │
         └────┬────┘      │      └────┬──────┘
              │           │           │
         ┌────▼───────────▼───────────▼───┐
         │      Home Server (Docker)      │
         │                                │
         │  ┌──────────────────────────┐  │
         │  │ Nginx Proxy Manager      │  │
         │  │ (80, 81, 443)            │  │
         │  └────┬─────────────────────┘  │
         │       │                        │
         │  ┌────▼─────────────────────┐  │
         │  │ AdGuard Home             │  │
         │  │ (53/DNS, 3001/UI)        │  │
         │  └──────────────────────────┘  │
         │                                │
         │  ┌──────────────────────────┐  │
         │  │ Twingate Connector       │  │
         │  │ (host network)           │  │
         │  └──────────────────────────┘  │
         │                                │
         │  ┌──────────────────────────┐  │
         │  │ Cloudflare DDNS          │  │
         │  └──────────────────────────┘  │
         └────────────────────────────────┘
```

### Network Flow

1. **External Traffic**: Cloudflare → Router (ports 80/443) → NPM → Services
2. **VPN Traffic**: Twingate → Connector (host network) → Services
3. **Local Traffic**: Device → AdGuard DNS (53) → Internet
4. **Admin Access**: LAN → NPM (81), AdGuard (3001)

### Data Persistence

All data stored in `/srv/docker/`:
```
/srv/docker/
├── nginx-proxy-manager/
│   ├── data/          # NPM database and config
│   └── letsencrypt/   # SSL certificates
└── adguard/
    ├── work/          # AdGuard runtime data
    └── conf/          # AdGuard configuration
```

---

## Manual Installation

### Prerequisites

**System Requirements:**
- Ubuntu Server 24.04 LTS (or any Debian-based)
- 4GB+ RAM (8GB recommended)
- 32GB+ disk space (128GB SSD recommended)
- Static IP address
- Internet connectivity

**Optional but Recommended:**
- **SSH Access**: For remote management
  - During Ubuntu installation: Check "Install OpenSSH server"
  - After installation: `sudo apt install openssh-server`
  - Connect from another machine: `ssh username@server-ip`
  - Makes configuration much easier!

**Optional Accounts:**
- Cloudflare account + API token (for DDNS)
- Twingate account + connector tokens (for VPN)
- Domain name (for SSL certificates)

### Step 1: Install System

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install base tools
sudo apt install -y git curl wget nano htop

# Set timezone
sudo timedatectl set-timezone Europe/Bratislava
```

### Step 2: Install Pi-Commander

```bash
# Clone repository
git clone https://github.com/martin-gomola/pi-commander.git
cd pi-commander

# Run installer (installs Docker, tools, sets up directories)
sudo ./install-control-plane.sh

# IMPORTANT: Log out and back in for docker group
exit
# Then SSH back in
```

### Step 3: Configure Environment

```bash
cd ~/pi-commander

# Option A: Interactive wizard (recommended)
### Step 3: Configure Services

```bash
# Copy .env.example to .env for each service
cd docker/nginx-proxy-manager && cp .env.example .env && cd ../..
cd docker/adguard && cp .env.example .env && cd ../..
cd docker/twingate && cp .env.example .env && cd ../..
cd docker/cloudflare-ddns && cp .env.example .env && cd ../..

# Edit each .env file with your values
nano docker/nginx-proxy-manager/.env
nano docker/adguard/.env
nano docker/twingate/.env
nano docker/cloudflare-ddns/.env
```

### Step 4: Deploy Services

```bash
# Deploy all core services
make deploy-all
```

### Step 5: Verify

```bash
# Check container status
docker ps

# Run health checks
make health

# Check logs if issues
docker logs <container-name> --tail 50
```

---

## Configuration Details

### Environment Variables

Each service has its own `.env` file with specific variables:

**docker/nginx-proxy-manager/.env:**
```bash
NGINX_PROXY_HTTP=80
NGINX_PROXY_ADMIN=81
NGINX_PROXY_HTTPS=443
INITIAL_ADMIN_EMAIL=admin@example.com
INITIAL_ADMIN_PASSWORD=changeme
TZ=Europe/Bratislava
```

**docker/adguard/.env:**
```bash
ADGUARD_DNS_TCP=53
ADGUARD_DNS_UDP=53
ADGUARD_SETUP_PORT=3004    # Initial setup only
ADGUARD_WEB_PORT=3001      # Admin UI
ADGUARD_HTTPS_PORT=8443    # DNS-over-HTTPS (optional)
ADGUARD_DOT_PORT=853       # DNS-over-TLS (optional)
TZ=Europe/Bratislava
```

**docker/twingate/.env (Optional):**
```bash
TWINGATE_NETWORK=your-network
TWINGATE_ACCESS_TOKEN=your-token
TWINGATE_REFRESH_TOKEN=your-token
```

**docker/cloudflare-ddns/.env (Optional):**
```bash
CLOUDFLARE_API_TOKEN=your-token
CLOUDFLARE_DOMAINS=domain.com,www.domain.com,*.domain.com
```

### Docker Compose Structure

Each service has its own directory with local configuration:
```
docker/
├── nginx-proxy-manager/
│   ├── docker-compose.yml
│   └── .env
├── adguard/
│   ├── docker-compose.yml
│   └── .env
├── twingate/
│   ├── docker-compose.yml
│   └── .env
└── cloudflare-ddns/
    ├── docker-compose.yml
    └── .env
```

All compose files use `env_file: .env` for local configuration.

---

## Network Configuration

### Port Mapping Reference

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| NPM | 80 | TCP | HTTP |
| NPM | 81 | TCP | Admin UI |
| NPM | 443 | TCP | HTTPS |
| AdGuard | 53 | TCP/UDP | DNS |
| AdGuard | 3001 | TCP | Web UI |
| AdGuard | 3004 | TCP | Initial setup |
| Twingate | host | - | Host network mode |

### Firewall Rules (Optional)

```bash
# If using UFW
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 81/tcp    # NPM Admin (restrict to LAN only)
sudo ufw allow 53        # DNS
sudo ufw enable
```

### Router Port Forwarding (For Internet Access)

Forward these to your server IP:
- Port 80 → Server:80 (HTTP)
- Port 443 → Server:443 (HTTPS)

**Security:** Only port 80/443 should be exposed to internet. All admin interfaces (81, 3001) should be LAN-only.

---

## Advanced Operations

### Backup Strategy

**Automated (Included):**
- Weekly full backup (Sunday 2 AM)
- Retains 7 weeks of backups
- Location: `/srv/backups/`

**Manual Backup:**
```bash
make backup
```

**Restore from Backup:**
```bash
make restore BACKUP_FILE=/srv/backups/pi-commander-YYYYMMDD.tar.gz
```

### SSL Certificates

**Let's Encrypt via NPM:**
1. Ensure ports 80/443 forwarded to server
2. Add proxy host in NPM
3. Request SSL certificate
4. NPM handles renewal automatically

**Certificates stored:**
`/srv/docker/nginx-proxy-manager/letsencrypt/`

### Updates

**Automated:**
```bash
# Pull latest code and redeploy changed services
make update
```

**Manual:**
```bash
# Update specific service
make update-service SERVICE=nginx-proxy-manager

# Check for available updates
make check-updates
```

### Monitoring

**Health Checks:**
```bash
make health          # Run all health checks
make status          # Show system status
make lazydocker      # Interactive Docker UI
```

**Logs:**
```bash
# Individual services
make logs-npm
make logs-adguard
make logs-uptime

# Or directly
docker logs <container-name> --tail 100 -f
```

### Maintenance

**Cron Jobs (Auto-configured):**
```bash
# View cron status
make cron-status

# Manually setup/remove
make backup-cron-setup
make reboot-cron-setup
make backup-cron-remove
```

**System Cleanup:**
```bash
# Remove unused Docker resources
docker system prune -a --volumes

# Check disk usage
docker system df
df -h /srv/docker
```

---

## Customization

### Adding Custom Services

1. Create new directory: `docker/my-service/`
2. Add `docker-compose.yml`
3. Copy `.env.example` to `.env` and configure
4. Use `env_file: .env` in docker-compose.yml
5. Deploy: `cd docker/my-service && docker-compose up -d`

### Modifying Network

Default network: `pi-commander_proxy_net` (bridge)

To change:
1. Edit `docker/nginx-proxy-manager/docker-compose.yml`
2. Update network settings in other services
3. Redeploy all services

### Custom Scripts

Add custom scripts to `scripts/`:
- Follow existing naming conventions
- Make executable: `chmod +x scripts/my-script.sh`
- Document in `scripts/README.md`

---

## Troubleshooting

### Pre-flight Checks

The installer runs these checks:
- RAM (4GB+ required)
- Disk (32GB+ required)
- Internet connectivity
- Port availability (80, 81, 443, 53)
- Architecture (x86_64)

### Common Issues

**Port 53 already in use:**
```bash
# Disable systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
```

**Permission denied (Docker):**
```bash
# Ensure you're in docker group
groups | grep docker

# If not, log out and back in
```

**Container won't start:**
```bash
# Check logs
docker logs <container-name> --tail 50

# Check port conflicts
sudo ss -tulpn | grep :<PORT>
```

### Diagnostics

```bash
# Generate full diagnostic report
./scripts/diagnostics.sh > diagnostics.txt

# Health check all services
make health

# Check specific service
docker inspect <container-name>
```

For more issues: [Troubleshooting Guide](troubleshooting.md)

---

## Performance Tuning

### System Limits

Increase open file limits for Docker:
```bash
sudo nano /etc/sysctl.conf
```
Add:
```
fs.file-max = 65535
```
Apply:
```bash
sudo sysctl -p
```

### Docker Logging

Limit log sizes (add to compose files):
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Disk I/O

Use SSD for `/srv/docker` for best performance.

---

## Security Hardening

### Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow from 192.168.1.0/24 to any port 81    # NPM admin (LAN only)
sudo ufw enable
```

### SSH Hardening

```bash
sudo nano /etc/ssh/sshd_config
```
```
PermitRootLogin no
PasswordAuthentication no  # Use SSH keys
Port 22222                  # Non-standard port
```

### Docker Socket

Never expose Docker socket to containers unless absolutely necessary.

### Regular Updates

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Container updates
make update
```

---

## Migration & Scaling

### Migrating to New Hardware

1. Backup on old server: `make backup`
2. Install Pi-Commander on new server
3. Copy `/srv/backups/` to new server
4. Restore: `make restore BACKUP_FILE=...`
5. Update each service's `.env` file with new IP if needed

### Adding More Services

See [homelab-services](https://github.com/martin-gomola/homelab-services) for additional Docker stacks.

---

## Reference

**Key Files:**
- `docker/*/. env` - Service configurations
- `Makefile` - Automation commands
- `install-control-plane.sh` - System installer
- `bootstrap.sh` - One-command installer

**Directories:**
- `/srv/docker/` - Persistent data
- `/srv/backups/` - Automated backups
- `~/pi-commander/` - Repository

**Documentation:**
- [Quick Start](../README.md) - For beginners
- [First Steps](first-steps.md) - Post-install guide
- [Troubleshooting](troubleshooting.md) - Common issues
- [Cloudflare Setup](cloudflare-setup.md) - DNS/DDNS
- [Port Mapping](port-mapping.md) - Port reference

---

## Support

**Issues:** Check [Troubleshooting](troubleshooting.md) first  
**GitHub:** [martin-gomola/pi-commander](https://github.com/martin-gomola/pi-commander)  
**Diagnostics:** `./scripts/diagnostics.sh`

This guide is for advanced users who want deep understanding. Most users should use the Quick Start instead.
