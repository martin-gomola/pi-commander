# Scripts

Utility scripts for backup, maintenance, and troubleshooting.

## Shared Operator

### pi-commander

Shared command adapter for service discovery, compose lifecycle commands, health probes, and backup policy.

```bash
./scripts/pi-commander help
./scripts/pi-commander list-config
./scripts/pi-commander health
```

## Backup

### backup-ssl-certs.sh

Adapter for `./scripts/pi-commander backup-ssl`. Backs up NPM SSL certificates and database.

```bash
sudo ./scripts/backup-ssl-certs.sh
# or
make backup-ssl
```

Location: `/srv/backups/ssl-certs/`

### restore-ssl-certs.sh

Adapter for `./scripts/pi-commander restore-ssl`. Restores NPM from backup.

```bash
# List backups
sudo ./scripts/restore-ssl-certs.sh

# Restore specific backup
sudo ./scripts/restore-ssl-certs.sh /srv/backups/ssl-certs/backup.tar.gz
```

### backup-cron.sh

Weekly automated backup adapter for `./scripts/pi-commander backup-full`. Set up with:

```bash
make backup-cron-setup
```

Runs: Sunday 2 AM
Location: `/srv/backups/`
Retention: 7 weeks

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
| pi-commander | Shared operator CLI | Depends on command |
| backup-ssl-certs.sh | Backup SSL | Yes |
| restore-ssl-certs.sh | Restore SSL | Yes |
| backup-cron.sh | Weekly backup | Yes |
| diagnostics.sh | Debug info | No |
