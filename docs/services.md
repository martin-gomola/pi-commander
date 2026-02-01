# Services Guide

Configure the services included with Pi-Commander.

## Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| NPM | 80 | HTTP traffic |
| NPM | 81 | Admin panel |
| NPM | 443 | HTTPS traffic |
| AdGuard | 53 | DNS queries |
| AdGuard | 3001 | Admin panel |
| Twingate | - | Host network |
| DDNS | - | No ports |

Check ports in use:
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

---

## Nginx Proxy Manager

NPM handles reverse proxying and SSL certificates.

### Access

- URL: `http://your-server-ip:81`
- Default login: `admin@example.com` / `changeme`

### Get SSL Certificate

For HTTPS on your services:

1. Go to **SSL Certificates** → **Add SSL Certificate**
2. Select **Let's Encrypt**
3. Enter domains: `*.yourdomain.com`, `yourdomain.com`
4. Use **DNS Challenge** with Cloudflare:
   - Provider: Cloudflare
   - API Token: Your token (see Cloudflare section below)
5. Save and wait for certificate

### Add Proxy Host

For each service you want to expose:

1. Go to **Hosts** → **Proxy Hosts** → **Add**
2. Fill in:
   - **Domain**: `service.yourdomain.com`
   - **Forward Host**: `your-server-ip` or container name
   - **Forward Port**: Service port (e.g., 3001)
3. SSL tab:
   - **Certificate**: Select your wildcard cert
   - **Force SSL**: Yes

### Common Settings

**Websocket support** (for real-time apps):
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

**Large uploads**:
```nginx
client_max_body_size 100M;
```

Add these in the **Advanced** tab.

---

## AdGuard Home

AdGuard provides DNS-level ad blocking.

### Access

- URL: `http://your-server-ip:3001`
- Credentials: Set during first-time setup

### Configuration

AdGuard works out of the box. Optional tweaks:

1. **Filters** → Add custom blocklists
2. **Settings** → **DNS settings** → Enable DNSSEC
3. **Query Log** → Monitor blocked requests

### Point Devices to AdGuard

Set DNS on your devices or router to `your-server-ip`. See [Setup Guide](setup.md#configure-devices-to-use-adguard).

---

## Cloudflare DDNS

Updates your domain's DNS when your home IP changes.

### Prerequisites

- Domain name
- Free Cloudflare account

### Step 1: Add Domain to Cloudflare

1. Log in to [Cloudflare](https://cloudflare.com)
2. Click **Add a Site**
3. Enter your domain
4. Select Free plan
5. Update nameservers at your registrar (takes 1-24 hours)

### Step 2: Configure DNS Records

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | @ | your-server-ip | Proxied |
| A | * | your-server-ip | DNS only |
| CNAME | www | yourdomain.com | Proxied |

Note: Wildcard records can't be proxied on free plan.

### Step 3: Create API Token

1. Go to **My Profile** → **API Tokens**
2. Click **Create Token**
3. Use **Edit zone DNS** template
4. Scope to your domain
5. Copy token (shown once only)

Test your token:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 4: Configure Pi-Commander

Edit `docker/cloudflare-ddns/.env`:
```bash
CF_API_TOKEN=your-token
CF_ZONE_ID=your-zone-id
CF_DOMAIN=yourdomain.com
```

Deploy:
```bash
cd ~/pi-commander
make deploy-all
docker logs cloudflare-ddns
```

### SSL Settings in Cloudflare

1. Go to **SSL/TLS** → **Overview**
2. Set mode to **Full (strict)**
3. Enable **Always Use HTTPS**

---

## Twingate VPN

Twingate provides zero-trust remote access without exposing ports.

### Prerequisites

- Free [Twingate](https://twingate.com) account
- Connector tokens from Twingate dashboard

### Setup

1. Create network at [Twingate Admin](https://admin.twingate.com)
2. Add a connector
3. Copy the access and refresh tokens
4. Edit `docker/twingate/.env`:
   ```bash
   TWINGATE_NETWORK=your-network
   TWINGATE_ACCESS_TOKEN=your-access-token
   TWINGATE_REFRESH_TOKEN=your-refresh-token
   ```
5. Deploy:
   ```bash
   cd ~/pi-commander
   make deploy-all
   ```

### Add Resources

In Twingate admin:
1. Create resources for each service (e.g., `192.168.1.x:81`)
2. Assign to groups
3. Install Twingate client on your devices
4. Connect to access your services from anywhere

---

## DuckDNS (Alternative to Cloudflare)

Free dynamic DNS if you don't have a domain.

### Setup

1. Create account at [DuckDNS](https://duckdns.org)
2. Create a subdomain (e.g., `myhomelab.duckdns.org`)
3. Copy your token
4. Edit `docker/duckdns/.env`:
   ```bash
   DUCKDNS_SUBDOMAIN=myhomelab
   DUCKDNS_TOKEN=your-token
   ```
5. Deploy:
   ```bash
   cd ~/pi-commander
   make deploy-all
   ```

---

## Troubleshooting

### NPM Certificate Won't Generate

- Ports 80/443 must be open from internet
- Temporarily set Cloudflare proxy to "DNS only"
- Check Let's Encrypt rate limits (5 per week)

### DDNS Not Updating

```bash
docker logs cloudflare-ddns --tail 50
```

Common issues:
- Invalid API token
- Wrong domain in config
- Domain not active on Cloudflare

### Service Not Accessible

```bash
# Check service is running
docker ps | grep service-name

# Test direct access
curl http://your-server-ip:port

# Check NPM logs
docker logs nginx-proxy-manager --tail 50
```

---

## Maintenance

### Backup SSL Certificates
```bash
make backup-ssl
```

### Update Services
```bash
make update-service SERVICE=nginx-proxy-manager
```

### Check Certificate Expiry

NPM auto-renews Let's Encrypt certificates. Check status in SSL Certificates tab.
