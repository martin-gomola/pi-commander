# Updating Docker Services

How to update Pi-Commander services when new versions are available.

## Check for Updates

```bash
# Using dockcheck (recommended)
dockcheck.sh
# or
make check-updates

# Using lazydocker
make lazydocker
```

---

## Update Methods

### Using Makefile (Recommended)

```bash
cd ~/pi-commander

# Update specific service
make update-service SERVICE=nginx-proxy-manager
make update-service SERVICE=adguard
make update-service SERVICE=twingate
make update-service SERVICE=cloudflare-ddns
```

### Manual Update

```bash
cd ~/pi-commander/docker/<service-name>
docker-compose pull
docker-compose up -d
```

---

## Before Updating

1. **Backup first**
   ```bash
   make backup
   make backup-ssl
   ```

2. **Check release notes** for breaking changes
   - [NPM Releases](https://github.com/NginxProxyManager/nginx-proxy-manager/releases)
   - [AdGuard Releases](https://github.com/AdguardTeam/AdGuardHome/releases)

---

## After Updating

```bash
# Verify container is running
docker ps | grep <service-name>

# Check logs for errors
docker logs <container-name> --tail 50

# Test service access
curl -I http://localhost:<port>
```

---

## Rollback

If an update breaks something:

```bash
cd ~/pi-commander/docker/<service-name>
docker-compose down

# Restore backup
make restore-ssl BACKUP_FILE=/srv/backups/ssl-certs/npm-ssl-backup-LATEST.tar.gz

# Or pin to specific version in docker-compose.yml:
# image: jc21/nginx-proxy-manager:2.10.4
docker-compose up -d
```

---

## Update Schedule

| Service | Frequency | Notes |
|---------|-----------|-------|
| Nginx Proxy Manager | Monthly | Check release notes |
| AdGuard Home | Quarterly | Stable, rarely needs updates |
| Cloudflare DDNS | Rarely | Only if issues |
| Twingate | As needed | Usually auto-updates |
