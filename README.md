# Pi-Commander

Core infrastructure for self-hosted servers - Reverse proxy, DNS, VPN, and DDNS management.

## Why I built this

I had an old Raspberry Pi 3B collecting dust. I wanted to turn it into something useful, a minimal home server that just works. Later I upgraded to a Zotac mini PC for a bit more headroom.

I tried Portainer, Pi-hole, Technitium, plain Nginx and WireGuard before settling on lazydocker, AdGuard, NPM and Twingate. The lesson: if you pick only what you need, self-hosting doesn't have to be complicated. Pi-Commander runs stable on my setup (40+ days uptime so far) because it does less, not more.

I switched to lazydocker for quick container monitoring and log checks. Combined with Cursor's SSH skill, I can manage the server runtime directly from my editor.

If you want a simple foundation for your home server, this might save you some time.

---

## Quick Start

### 🚀 Easy Install

**If you have git:**
```bash
git clone https://tinyurl.com/pi-commander
cd pi-commander
./setup.sh
```

**Fresh server (no git yet):**
```bash
curl -fsSL tinyurl.com/pi-commander-setup|bash
```

> **💡 Short URLs:**  
> [tinyurl.com/pi-commander](https://tinyurl.com/pi-commander) → GitHub repo  
> [tinyurl.com/pi-commander-setup](https://tinyurl.com/pi-commander-setup) → Setup script

**This will:**
- Install Docker & Docker Compose
- Install lazydocker and dockcheck
- Create directory structure (`/srv/docker`, `/srv/backups`)
- Clone Pi-Commander repository

---

### 🛠️ After Installation

Configure each service manually by copying `.env.example` to `.env` and editing:

```bash
cd ~/pi-commander

# Configure each service
cd docker/nginx-proxy-manager && cp .env.example .env && nano .env
cd ../adguard && cp .env.example .env && nano .env
cd ../twingate && cp .env.example .env && nano .env
cd ../cloudflare-ddns && cp .env.example .env && nano .env  # or duckdns

# Deploy all services
cd ~/pi-commander
make deploy-all
```

**Access your services:**
- **NPM Admin**: `http://your-server-ip:81` (default: admin@example.com / changeme)
- **AdGuard Home**: `http://your-server-ip:3001`

📖 **Next:** [Setup Guide](docs/setup.md) | 🆘 **Issues?** [Troubleshooting](docs/troubleshooting.md)

---

## What's Included

| Service | Purpose | Port |
|---------|---------|------|
| **Nginx Proxy Manager** | Reverse proxy + SSL | 80, 81, 443 |
| **AdGuard Home** | DNS + Ad-blocking | 53, 3001 |
| **Twingate** | Zero-trust VPN | host mode |
| **Cloudflare DDNS** | Auto DNS updates | - |

**Additional Tools (installed automatically):**
- `lazydocker` - Docker terminal UI (run: `lazydocker`)
- `dockcheck` - Container update checker (run: `dockcheck.sh`)

---

## Architecture

```
    INTERNET                           LAN ONLY
        │                                  │
        ↓                                  ↓
    Cloudflare                     ┌─────────────┐
        │                          │   AdGuard   │
        ↓                          │  DNS (:53)  │
    ┌────────────────┐             └─────────────┘
    │ NPM (:80/443)  │ ← Only exposed ports
    └────────────────┘
           │
    ┌──────┴──────┐
    ↓             ↓
 Twingate      DDNS
 (outbound)  (outbound)
```

**Security:**
- Only ports 80/443 exposed to internet (via Cloudflare)
- AdGuard DNS serves local network only (never exposed)
- Twingate/DDNS connect outbound, no inbound ports needed
- Admin panels (81, 3001) accessible from LAN only

---

## Manual Installation

```bash
git clone https://github.com/martin-gomola/pi-commander.git
cd pi-commander

# Copy .env.example to .env in each service directory
cd docker/nginx-proxy-manager && cp .env.example .env && cd ../..
cd docker/adguard && cp .env.example .env && cd ../..
cd docker/twingate && cp .env.example .env && cd ../..
cd docker/cloudflare-ddns && cp .env.example .env && cd ../..

# Configure each .env file, then deploy
make deploy-all
```

---

## Essential Commands

```bash
make help           # Show all commands
make deploy-all     # Deploy all services
make update         # Update containers
make health         # Health checks
make backup         # Full backup
make lazydocker     # Docker UI
```

[View all commands →](Makefile)

---

## Documentation

- [Setup Guide](docs/setup.md) - Post-install configuration
- [Services Guide](docs/services.md) - Configure NPM, Cloudflare, Twingate
- [Troubleshooting](docs/troubleshooting.md) - Common issues and fixes

---

## Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| **RAM** | 2GB | 4GB+ |
| **Storage** | 16GB | 32GB+ SSD |
| **CPU** | 2 cores | 4+ cores |
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| **Architecture** | x86_64, ARM64, ARMv7 | x86_64, ARM64 |

**💡 Setup Tip:** During Ubuntu Server installation, enable "Install OpenSSH server" for remote management.

**Tested on:**
- x86_64: Standard PCs, old laptops, Intel NUCs
- ARM64: Raspberry Pi 4/5, Orange Pi, Rock Pi
- ARMv7: Raspberry Pi 3 (limited testing)

---

## Related

- **[homelab-services](https://github.com/martin-gomola/homelab-services)** - Additional self-hosted apps (AFFiNE, Mealie, Plausible, etc.)

---

## License

MIT License
