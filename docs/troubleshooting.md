# Troubleshooting Guide

Common issues and solutions when installing or running Pi-Commander.

## Installation Issues

### "This script must be run with sudo"

**Symptom:** Install script fails immediately.

**Fix:**
```bash
sudo ./install-control-plane.sh
```

### "Disk space: XGB available (32GB+ required)"

**Symptom:** Pre-flight check fails due to insufficient disk space.

**Fix:**
- Use a larger drive (128GB+ SSD recommended)
- Or free up space: `sudo apt clean && docker system prune -a`

### "No internet connection detected"

**Symptom:** Pre-flight check fails.

**Fix:**
```bash
# Test connectivity
ping -c 3 google.com

# Check network interface
ip addr show

# Check DNS
cat /etc/resolv.conf
```

---

## Docker Issues

### "Permission denied while trying to connect"

**Symptom:** `Cannot connect to the Docker daemon`

**Fix:**
```bash
# Log out and back in, or run:
newgrp docker

# Verify you're in docker group:
groups | grep docker
```

### "Port already in use"

**Symptom:** `port 80 already in use` or similar.

**Fix:**
```bash
# Find what's using the port
sudo ss -tulpn | grep :80

# Common culprits:
sudo systemctl stop apache2      # Apache web server
sudo systemctl disable apache2

sudo systemctl stop nginx        # Nginx
sudo systemctl disable nginx

# Port 53 (DNS) often used by systemd-resolved:
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
```

### "Docker Compose not found"

**Symptom:** `docker-compose: command not found`

**Fix:**
```bash
# Check if Docker Compose plugin is installed
docker compose version

# If not, reinstall:
sudo apt install docker-compose-plugin

# Or use plugin syntax:
docker compose up -d  # instead of docker-compose up -d
```

---

## Service Issues

### NPM Won't Start

**Symptom:** Nginx Proxy Manager container keeps restarting.

**Fix:**
```bash
# Check logs
docker logs nginx-proxy-manager --tail 50

# Common issues:
# 1. Ports 80/81/443 in use
sudo ss -tulpn | grep -E ':(80|81|443)'

# 2. Permissions
sudo chown -R root:root /srv/docker/nginx-proxy-manager
cd ~/pi-commander/docker/nginx-proxy-manager
docker-compose restart
```

### AdGuard DNS Not Working

**Symptom:** DNS queries fail.

**Fix:**
```bash
# Test DNS directly
dig @localhost google.com

# Check if port 53 is bound
sudo ss -tulpn | grep :53

# Restart AdGuard
cd ~/pi-commander/docker/adguard-twingate
docker-compose restart adguard-home

# Check logs
docker logs adguard-home --tail 50
```

### Docker Registry Issues

**Symptom:** Cannot pull images during deployment.

**Fix:**
```bash
# Check Docker Hub status
curl -s https://status.docker.com/

# Try manual pull to see error
docker pull nginx:latest

# Clear Docker cache and retry
docker system prune -a
make deploy
```

---

## Network Issues

### Can't Access Services from Other Devices

**Symptom:** Services work on `localhost` but not from other devices.

**Fix:**
```bash
# Check firewall
sudo ufw status

# If firewall is active, allow ports:
sudo ufw allow 80
sudo ufw allow 81
sudo ufw allow 443
sudo ufw allow 3001

# Check if services are bound to all interfaces
ss -tulpn | grep -E ':(80|81|443|3001)'
# Should show 0.0.0.0:PORT, not 127.0.0.1:PORT
```

### Cloudflare DDNS Not Updating

**Symptom:** Domain doesn't point to your server.

**Fix:**
```bash
# Check logs
docker logs cloudflare-ddns --tail 50

# Test API token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json"

# Verify domains in .env
cat ~/pi-commander/docker/cloudflare-ddns/.env | grep CLOUDFLARE
```

---

## SSL Certificate Issues

### "Certificate not generating"

**Symptom:** Let's Encrypt fails in NPM.

**Fix:**
```bash
# Ensure ports 80/443 are accessible from internet
# Check router port forwarding

# Temporarily disable Cloudflare proxy (gray cloud) if using

# Check Let's Encrypt rate limits
# Max 5 certificates per week per domain

# Try DNS challenge instead of HTTP challenge
```

### "NET::ERR_CERT_AUTHORITY_INVALID"

**Symptom:** Browser shows SSL warning.

**Fix:**
- This is normal for self-signed certificates
- Use Let's Encrypt via NPM for valid certificates
- Or add exception in browser (for development only)

---

## Configuration Issues

### ".env file not found"

**Symptom:** `docker-compose` complains about missing variables.

**Fix:**
```bash
# Create .env files from examples
cd ~/pi-commander

# For each service:
cd docker/nginx-proxy-manager && cp .env.example .env && cd ../..
cd docker/adguard && cp .env.example .env && cd ../..
cd docker/twingate && cp .env.example .env && cd ../..
cd docker/cloudflare-ddns && cp .env.example .env && cd ../..

# Edit each with your values
nano docker/nginx-proxy-manager/.env
```

### "Can't connect to services after reboot"

**Symptom:** Services don't start automatically.

**Fix:**
```bash
# Check if containers are set to restart
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.RestartPolicy}}"

# If restart policy is missing, recreate containers:
cd ~/pi-commander
make deploy-all
```

---

## Performance Issues

### Server Running Slow

**Symptoms:** High load, sluggish response.

**Fix:**
```bash
# Check resource usage
htop

# Check Docker stats
docker stats --no-stream

# Check disk I/O
iostat -x 1 5

# Clean up Docker
docker system prune -a --volumes

# Run health check
cd ~/pi-commander
make health
```

### Out of Disk Space

**Symptom:** `no space left on device`

**Fix:**
```bash
# Check disk usage
df -h
du -sh /srv/docker/*

# Clean Docker
docker system prune -a --volumes

# Check logs taking up space
find /var/log -type f -size +100M

# Clean old backups
ls -lh /srv/backups/
```

---

## Git Issues

### "Repository not clean" when updating

**Symptom:** `make update` fails with git errors.

**Fix:**
```bash
cd ~/pi-commander

# See what changed
git status

# Discard local changes
git reset --hard HEAD

# Pull latest
git pull origin main
```

---

## Recovery

### "Everything is broken"

**Nuclear option - clean reinstall:**

```bash
# Stop all containers
cd ~/pi-commander
docker stop $(docker ps -aq)

# Remove containers
docker rm $(docker ps -aq)

# Remove volumes (deletes all data)
docker volume prune -a

# Re-run installation
sudo ./install-control-plane.sh

# Restore from backup if you have one
make restore BACKUP_FILE=/srv/backups/pi-commander-YYYYMMDD.tar.gz

# Or start fresh
make deploy-all
```

---

## Getting Help

If none of these solutions work:

1. **Check logs:**
   ```bash
   docker logs <container-name> --tail 100
   ```

2. **Check GitHub Issues:**
   https://github.com/martin-gomola/pi-commander/issues

3. **Create a new issue with:**
   - OS version: `lsb_release -a`
   - Docker version: `docker --version`
   - Container status: `docker ps -a`
   - Relevant logs
   - Steps to reproduce

---

## Quick Diagnostics

Run this to gather system info for troubleshooting:

```bash
#!/bin/bash
# Diagnostic script

echo "=== System Info ==="
uname -a
lsb_release -a

echo ""
echo "=== Resources ==="
free -h
df -h

echo ""
echo "=== Docker ==="
docker --version
docker ps -a

echo ""
echo "=== Ports ==="
ss -tulpn | grep -E ':(80|81|443|53|3001)'

echo ""
echo "=== Recent Logs ==="
docker logs nginx-proxy-manager --tail 20 2>&1 | grep -i error
docker logs adguard-home --tail 20 2>&1 | grep -i error
```

Save this as `diagnostics.sh`, run with `bash diagnostics.sh > diagnostics.txt`, and share the output when asking for help.
