# Pi-Commander Scripts

Quick reference for utility scripts. See [full documentation](../docs/scripts-guide.md) for detailed usage.

## 🔐 SSL Certificate Management

### backup-ssl-certs.sh
Backs up Nginx Proxy Manager SSL certificates and database.

```bash
# Manual backup
sudo ./backup-ssl-certs.sh

# Setup automated daily backups (recommended)
sudo crontab -e
# Add: 0 3 * * * /home/matie/pi-commander/scripts/backup-ssl-certs.sh >> /var/log/ssl-backup.log 2>&1
```

**Backup location**: `/srv/backups/ssl-certs/npm-ssl-backup-*.tar.gz`
**Retention**: 30 days (automatic cleanup)

### restore-ssl-certs.sh
Restores NPM SSL certificates from backup.

```bash
# List available backups
sudo ./restore-ssl-certs.sh

# Restore specific backup
sudo ./restore-ssl-certs.sh /srv/backups/ssl-certs/npm-ssl-backup-20251130-030000.tar.gz
```

**Safety**: Creates current data backup before restore

## ⚡ System Optimization

### optimize-system.sh
Applies performance optimizations for ZOTAC ZBOX hardware.

```bash
# Run once on fresh install
sudo ./optimize-system.sh
```

**What it does:**
- Optimizes swap settings (vm.swappiness=10)
- Configures Docker logging (max 10MB, 3 files)
- Tunes network performance (BBR, buffer sizes)
- Creates maintenance scripts:
  - `/usr/local/bin/docker-cleanup.sh`
  - `/root/health-check.sh`

## 📖 Full Documentation

See [scripts-guide.md](../docs/scripts-guide.md) for:
- Detailed usage instructions
- Configuration options
- Common workflows
- Troubleshooting
- Maintenance schedules

## 🚀 Quick Workflows

**Before NPM changes:**
```bash
sudo ./backup-ssl-certs.sh
# Make changes...
# If needed: sudo ./restore-ssl-certs.sh /srv/backups/ssl-certs/LATEST.tar.gz
```

**New server setup:**
```bash
sudo ./optimize-system.sh
# Setup cron jobs for automated backups
```

**Performance issues:**
```bash
sudo /root/health-check.sh
sudo /usr/local/bin/docker-cleanup.sh
```

---

**All scripts require sudo** (root access needed for system changes)
