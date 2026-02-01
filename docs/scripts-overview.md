# Script Structure

## Core Scripts (Root Directory)

### `install.sh` ⭐ Main Entry Point
**Purpose:** One-command installation for fresh Ubuntu Server  
**Usage:**
```bash
# From cloned repo
./install.sh

# Or remote install
curl -fsSL https://raw.githubusercontent.com/martin-gomola/pi-commander/main/install.sh | bash
```

**What it does:**
1. Clones repository (if running remotely)
2. Runs pre-flight checks
3. Calls `install-control-plane.sh` (Docker setup)
4. Creates static homepage from template
5. Offers configuration wizard
6. Optionally deploys services

---

### `install-control-plane.sh` 🔧 System Setup
**Purpose:** Install Docker and setup directory structure  
**Usage:** `sudo ./install-control-plane.sh` (called by install.sh)  
**Requires:** sudo privileges

**What it does:**
1. Installs Docker Engine
2. Installs Docker Compose
3. Creates `/srv/docker/` and `/srv/backups/`
4. Creates core service directories
5. Installs lazydocker (Docker TUI)
6. Installs dockcheck (update checker)
7. Creates Docker networks

---

### `deploy-auto.sh` 🚀 Auto-Deploy System
**Purpose:** Pull git changes and auto-deploy affected services  
**Usage:** `./deploy-auto.sh [command]`

**Commands:**
- `deploy` - Auto-deploy changed services
- `deploy-all` - Force deploy all services
- `status` - Show git & container status

**What it does:**
- Detects which services changed in git
- Only redeploys affected services
- Atomic deployments with rollback
- Lock file prevents concurrent runs

---

## Helper Scripts (scripts/)

### `scripts/config-wizard.sh` 🧙 Configuration Wizard
**Purpose:** Interactive service configuration  
**Usage:** `./scripts/config-wizard.sh` or `make wizard`

**Creates:**
- `docker/nginx-proxy-manager/.env`
- `docker/adguard/.env`
- `docker/cloudflare-ddns/.env` OR `docker/duckdns/.env`
- `docker/twingate/.env` (if enabled)

---

### `scripts/preflight-check.sh` ✅ System Validation
**Purpose:** Validate system meets requirements  
**Usage:** `./scripts/preflight-check.sh` or `make preflight`

**Checks:**
- OS compatibility (Ubuntu/Debian)
- RAM (2GB minimum, 4GB recommended)
- Disk space (16GB minimum, 32GB recommended)
- Port availability (53, 80, 443, 81)
- Internet & DNS
- Docker installation

---

### `scripts/diagnostics.sh` 🔍 Troubleshooting
**Purpose:** Gather system info for debugging  
**Usage:** `./scripts/diagnostics.sh > diagnostics.txt`

---

### Backup Scripts

**`scripts/backup-ssl-certs.sh`**
- Backs up NPM SSL certificates & database
- Run manually or via cron

**`scripts/restore-ssl-certs.sh`**
- Restores NPM backups
- Lists available backups if no file specified

**`scripts/backup-cron.sh`**
- Weekly full system backup
- Add to crontab: `0 2 * * 0 /path/to/backup-cron.sh`

---

### Utility Scripts

**`scripts/setup-adguard-doh.sh`**
- Generates self-signed cert for AdGuard DoH
- Restarts AdGuard service

**`scripts/optimize-system.sh`**
- System performance tuning
- Docker logging configuration
- Network optimizations

---

## Removed Scripts (Consolidated)

**`bootstrap.sh`** ❌ Removed (duplicate of install.sh)  
**`setup`** ❌ Removed (unnecessary wrapper)

---

## Script Flow Chart

```
User starts installation
    ↓
./install.sh (or curl remote)
    ↓
    ├─→ Clone repo (if remote)
    ↓
    ├─→ scripts/preflight-check.sh
    ↓
    ├─→ sudo ./install-control-plane.sh
    │   ├─→ Install Docker
    │   ├─→ Install Docker Compose
    │   ├─→ Create directories
    │   └─→ Setup tools
    ↓
    ├─→ Copy static template
    ↓
    ├─→ scripts/config-wizard.sh (optional)
    │   └─→ Generate all .env files
    ↓
    └─→ make deploy-all (optional)
        └─→ docker-compose up for each service
```

---

## Automation Flow

```
Cron or Manual Update
    ↓
./deploy-auto.sh deploy
    ↓
    ├─→ git fetch origin
    ↓
    ├─→ Detect changed services
    ↓
    ├─→ For each changed service:
    │   ├─→ Pull new docker-compose.yml
    │   ├─→ Pull new images
    │   ├─→ docker-compose up -d
    │   └─→ Verify health
    ↓
    └─→ Report status
```

---

## Design Principles

1. **Single Entry Point:** `install.sh` is the only script users need to run
2. **Idempotent:** All scripts can be run multiple times safely
3. **No Duplication:** Each script has one clear purpose
4. **Helper Scripts:** Optional utilities in `scripts/`
5. **Automation:** `deploy-auto.sh` handles updates
6. **Clear Naming:** Script names describe their purpose

---

## Quick Reference

**Fresh Install (No Git):**
```bash
curl -fsSL tinyurl.com/picommander-install|bash
```

**Fresh Install (Have Git):**
```bash
git clone https://tinyurl.com/picommander
cd pi-commander
./install.sh
```

**Configure Services:**
```bash
make wizard
```

**Deploy Services:**
```bash
make deploy-all
```

**Update & Auto-Deploy:**
```bash
./deploy-auto.sh deploy
```

**Health Check:**
```bash
make health
```

**Backup:**
```bash
sudo scripts/backup-ssl-certs.sh
```
