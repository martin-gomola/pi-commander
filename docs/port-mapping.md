# Port Mapping Reference

All ports used by Pi-Commander core services.

## Core Services

| Service | External Port | Internal Port | Purpose |
|---------|---------------|---------------|---------|
| Nginx Proxy Manager | 80 | 80 | HTTP traffic |
| Nginx Proxy Manager | 81 | 81 | Admin panel |
| Nginx Proxy Manager | 443 | 443 | HTTPS traffic |
| AdGuard Home | 53 (TCP/UDP) | 53 | DNS queries |
| AdGuard Home | 3004 | 3000 | Initial setup |
| AdGuard Home | 3001 | 80 | Admin panel |
| AdGuard Home | 8443 | 443 | HTTPS/DoH |
| AdGuard Home | 853 | 853 | DNS-over-TLS |
| Twingate | N/A | N/A | Host network mode |
| Cloudflare DDNS | N/A | N/A | No ports exposed |

## Quick Commands

```bash
# See all ports in use
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check if a specific port is in use
sudo netstat -tulpn | grep <PORT>
```

## Adding New Services

1. Choose an unused port
2. Add to service's `.env` file
3. Reference in `docker-compose.yml`:
   ```yaml
   ports:
     - "${MY_SERVICE_PORT}:80"
   ```

## Application Services

For additional services (Mealie, AFFiNE, etc.), see [homelab-services](https://github.com/martin-gomola/homelab-services).
