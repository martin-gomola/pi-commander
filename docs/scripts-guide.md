# Scripts Guide

Utility scripts for maintaining your Pi-Commander server.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `backup-ssl-certs.sh` | Backup NPM SSL certificates |
| `restore-ssl-certs.sh` | Restore NPM SSL certificates |
| `backup-cron.sh` | Automated weekly backup |
| `optimize-system.sh` | System performance tuning |
| `setup-env-links.sh` | Create .env symlinks |

---

## SSL Certificate Backup

### Manual Backup

```bash
cd ~/pi-commander/scripts
sudo ./backup-ssl-certs.sh
```

Backups are stored in `/srv/backups/ssl-certs/`

### Restore from Backup

```bash
# List available backups
sudo ./restore-ssl-certs.sh

# Restore specific backup
sudo ./restore-ssl-certs.sh /srv/backups/ssl-certs/npm-ssl-backup-20251130-030000.tar.gz
```

The script will:
1. Stop NPM
2. Back up current data
3. Restore from backup
4. Restart NPM

---

## Automated Backups

### Setup Weekly Backup

```bash
cd ~/pi-commander
make backup-cron-setup   # Runs Sunday 2 AM
make reboot-cron-setup   # Reboots Sunday 4 AM
```

### Check Scheduled Tasks

```bash
make cron-status
```

### Manual Backup

```bash
make backup
```

Backups are stored in `/srv/backups/` and retained for 7 weeks.

---

## System Optimization

Run after fresh install to optimize performance:

```bash
cd ~/pi-commander/scripts
sudo ./optimize-system.sh
```

This configures:
- Swap settings (reduces swap usage)
- Docker logging (prevents disk fill)
- Network performance tuning

---

## Environment Symlinks

Create `.env` symlinks in Docker service directories:

```bash
make setup-env-links
```

This allows running `docker-compose up -d` without `--env-file` flag.

---

## Troubleshooting

**Script won't run:**
```bash
chmod +x ~/pi-commander/scripts/*.sh
```

**NPM won't start after restore:**
```bash
docker logs nginx-proxy-manager
cd ~/pi-commander/docker/nginx-proxy-manager
docker-compose restart
```

**Check backup logs:**
```bash
tail /var/log/pi-commander-backup.log
```
