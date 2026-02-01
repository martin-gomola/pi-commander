# Troubleshooting

Common issues and how to fix them.

## Installation

### "Permission denied" running Docker

You need to be in the docker group. Fix:
```bash
newgrp docker
# Or log out and back in
```

Verify:
```bash
groups | grep docker
```

### Port already in use

Find what's using the port:
```bash
sudo ss -tulpn | grep :80
```

Common fixes:
```bash
# Apache or Nginx running
sudo systemctl stop apache2 nginx
sudo systemctl disable apache2 nginx

# Port 53 (DNS) used by systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

---

## Docker

### Container keeps restarting

Check the logs:
```bash
docker logs container-name --tail 50
```

Common causes:
- Missing `.env` file
- Port conflict
- Permission issues

### Can't pull images

```bash
# Test connectivity
docker pull hello-world

# Clear cache and retry
docker system prune -a
make deploy-all
```

---

## NPM (Nginx Proxy Manager)

### Can't access admin panel

1. Check container is running: `docker ps | grep nginx`
2. Check port 81 isn't blocked: `sudo ss -tulpn | grep :81`
3. Check logs: `docker logs nginx-proxy-manager --tail 50`

### SSL certificate won't generate

- Ports 80/443 must be accessible from internet
- Check router port forwarding
- Set Cloudflare proxy to "DNS only" temporarily
- Let's Encrypt allows 5 certificates per week per domain

### 502 Bad Gateway

The target service isn't responding. Check:
```bash
# Is the service running?
docker ps | grep service-name

# Can you reach it directly?
curl http://your-server-ip:port
```

---

## AdGuard

### DNS not working

```bash
# Test DNS directly
dig @localhost google.com

# Check port 53
sudo ss -tulpn | grep :53

# Check logs
docker logs adguard-home --tail 50
```

### Clients not using AdGuard

- Verify device DNS settings point to your server IP
- Some devices ignore DHCP DNS (check device settings)
- Try rebooting your router after DNS changes

---

## Network

### Can't access services from other devices

Services work on localhost but not from other devices:

```bash
# Check firewall
sudo ufw status

# Allow ports if needed
sudo ufw allow 80
sudo ufw allow 81
sudo ufw allow 443
sudo ufw allow 3001
```

### Cloudflare DDNS not updating

```bash
docker logs cloudflare-ddns --tail 50
```

Common issues:
- Invalid API token
- Domain not on Cloudflare
- Wrong zone ID

Test your token:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Performance

### Server running slow

```bash
# Check resources
htop
docker stats --no-stream

# Clean up Docker
docker system prune -a --volumes
```

### Out of disk space

```bash
# Check usage
df -h
du -sh /srv/docker/*

# Clean Docker
docker system prune -a --volumes

# Check old backups
ls -lh /srv/backups/
```

---

## Recovery

### Reset everything

If nothing else works:

```bash
cd ~/pi-commander

# Stop all containers
docker stop $(docker ps -aq)

# Remove containers
docker rm $(docker ps -aq)

# Remove volumes (deletes all data)
docker volume prune -a

# Redeploy
make deploy-all
```

### Restore from backup

```bash
make restore BACKUP_FILE=/srv/backups/pi-commander-YYYYMMDD.tar.gz
```

---

## Get Help

### Run diagnostics

```bash
./scripts/diagnostics.sh > diagnostics.txt
```

### Check logs

```bash
docker logs container-name --tail 100
```

### GitHub Issues

[github.com/martin-gomola/pi-commander/issues](https://github.com/martin-gomola/pi-commander/issues)

Include:
- OS version: `lsb_release -a`
- Docker version: `docker --version`
- Container status: `docker ps -a`
- Relevant logs
