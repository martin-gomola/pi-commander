# Scripts

Utility scripts for backup, maintenance, and troubleshooting.

## Backup

### backup-ssl-certs.sh

Backs up NPM SSL certificates and database.

```bash
sudo ./scripts/backup-ssl-certs.sh
# or
make backup-ssl
```

Location: `/srv/backups/ssl-certs/`

### restore-ssl-certs.sh

Restores NPM from backup.

```bash
# List backups
sudo ./scripts/restore-ssl-certs.sh

# Restore specific backup
sudo ./scripts/restore-ssl-certs.sh /srv/backups/ssl-certs/backup.tar.gz
```

### backup-cron.sh

Weekly automated backup. Set up with:

```bash
make backup-cron-setup
```

Runs: Sunday 2 AM  
Location: `/srv/backups/`

## Troubleshooting

### diagnostics.sh

Generates system report for troubleshooting.

```bash
./scripts/diagnostics.sh > diagnostics.txt
```

Collects: System info, Docker status, container logs, network config, disk usage.

## Quick Reference

| Script | Purpose | Needs sudo |
|--------|---------|------------|
| backup-ssl-certs.sh | Backup SSL | Yes |
| restore-ssl-certs.sh | Restore SSL | Yes |
| backup-cron.sh | Weekly backup | Yes |
| diagnostics.sh | Debug info | No |
