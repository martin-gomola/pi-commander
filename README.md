# Pi-Commander

Core infrastructure for self-hosted servers - Reverse proxy, DNS, VPN, and DDNS management.

## Quick Start

### 🚀 Easy Install

**If you have git:**
```bash
git clone https://tinyurl.com/picommander
cd pi-commander
./install.sh
```

**Fresh server (no git yet):**
```bash
curl -fsSL tinyurl.com/picommander-install|bash
```

> **💡 Short URLs:**  
> [tinyurl.com/picommander](https://tinyurl.com/picommander) → GitHub repo  
> [tinyurl.com/picommander-install](https://tinyurl.com/picommander-install) → Install script

**This will:**
- ✅ Install git (if needed)
- ✅ Run pre-flight checks
- ✅ Install Docker & Docker Compose
- ✅ Offer interactive configuration wizard
- ✅ Deploy core services

---

### 🛠️ Advanced: Manual Setup

```bash
git clone https://github.com/martin-gomola/pi-commander.git
cd pi-commander
./scripts/preflight-check.sh  # Verify requirements
./scripts/config-wizard.sh     # Or manually edit .env files
make deploy-all
```

**That's it!** Access your services:
- **NPM Admin**: `http://your-server-ip:81` (default: admin@example.com / changeme)
- **AdGuard Home**: `http://your-server-ip:3001`

📖 **Next:** [First Steps Guide](docs/first-steps.md) | 🆘 **Issues?** [Troubleshooting](docs/troubleshooting.md)

---

## What's Included

| Service | Purpose | Port |
|---------|---------|------|
| **Nginx Proxy Manager** | Reverse proxy + SSL | 80, 81, 443 |
| **AdGuard Home** | DNS + Ad-blocking | 53, 3001 |
| **Twingate** | Zero-trust VPN | host mode |
| **Cloudflare DDNS** | Auto DNS updates | - |

Plus: **lazydocker** (Docker UI) and **dockcheck** (update checker)

---

## Architecture

```
    INTERNET → Cloudflare CDN
          ↓
    ┌────────────────────┐
    │   NPM (:80/443)    │  ← Reverse proxy + SSL
    └─────────┬──────────┘
         ┌────┼────┐
         ↓    ↓    ↓
    AdGuard Twingate DDNS
    DNS+Ads   VPN    Updates
```

**Key Design:** NPM routes all web traffic. AdGuard handles DNS for local network. Twingate provides secure remote VPN access.

[View detailed architecture →](docs/advanced-installation.md#architecture-overview)

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

[View detailed installation →](docs/advanced-installation.md)

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

📚 **[Documentation Hub](docs/README.md)** - Find the right guide

**Getting Started:**
- [Quick Start](#quick-start) - One-command install
- [First Steps](docs/first-steps.md) - Post-install essentials
- [Troubleshooting](docs/troubleshooting.md) - Common issues

**Configuration:**
- [Cloudflare Setup](docs/cloudflare-setup.md) - Domain + DDNS
- [Port Mapping](docs/port-mapping.md) - All ports reference

**Advanced:**
- [Advanced Installation](docs/advanced-installation.md) - Manual setup & internals
- [Updating Services](docs/updating-services.md) - Container updates

---

## Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| **RAM** | 4GB | 8GB+ |
| **Storage** | 32GB | 128GB+ SSD |
| **CPU** | 2 cores | 4+ cores |
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |

**💡 Setup Tip:** During Ubuntu Server installation, enable "Install OpenSSH server" for remote management.

---

## Related

- **[homelab-services](https://github.com/martin-gomola/homelab-services)** - Additional self-hosted apps (AFFiNE, Mealie, Plausible, etc.)

---

## License

MIT License
