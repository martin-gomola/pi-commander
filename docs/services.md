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

## Local SSL (LAN-Only Access)

Get valid HTTPS for local services without exposing anything to the internet. Access your services via clean URLs like `npm.home.yourdomain.com` from your LAN only.

### How It Works

1. **Cloudflare DNS** has `*.home.yourdomain.com` pointing to your local IP (192.168.1.x)
2. **NPM** gets SSL certificate via DNS-01 challenge (Cloudflare API)
3. **Result**: Valid HTTPS, but only accessible from your LAN

The DNS record is public, but it points to a private IP. External users can resolve the domain but can't reach your server.

### Prerequisites

- Domain with Cloudflare DNS (free tier works)
- Cloudflare API token

### Step 1: Add DNS Record in Cloudflare

1. Go to your domain in Cloudflare dashboard
2. **DNS** → **Add record**:
   - Type: `A`
   - Name: `*.home`
   - Content: `192.168.1.100` (your server's local IP)
   - Proxy status: **DNS only** (gray cloud)
3. Save

Cloudflare will show "reserved IP" warning. This is expected.

### Step 2: Get Wildcard Certificate in NPM

1. Open NPM: `http://your-server-ip:81`
2. **SSL Certificates** → **Add SSL Certificate** → **Let's Encrypt**
3. Domain names: `*.home.yourdomain.com`
4. Enable **Use a DNS Challenge**:
   - Provider: Cloudflare
   - API Token: Your Cloudflare API token
5. Save and wait for certificate

This works because DNS-01 only verifies domain ownership via DNS. It doesn't need to reach your server.

### Step 3: Create Proxy Hosts

In NPM, create a proxy host for each service:

| Subdomain | Forward To | Port |
|-----------|------------|------|
| `npm.home.yourdomain.com` | `127.0.0.1` | 81 |
| `adguard.home.yourdomain.com` | `127.0.0.1` | 3001 |

For each:

1. **Hosts** → **Proxy Hosts** → **Add**
2. Domain: `npm.home.yourdomain.com`
3. Forward Host: `127.0.0.1`
4. Forward Port: `81`
5. SSL tab: Select your wildcard cert, enable Force SSL

### Result

- `https://npm.home.yourdomain.com` works on your LAN
- Valid SSL certificate (green lock, no warnings)
- Nothing exposed to internet

### Why This Is Secure

- The `*.home` subdomain points to a private IP (192.168.x.x)
- Anyone on the internet can resolve the DNS, but they can't route to your LAN
- Your main domain and other subdomains remain unaffected
- No ports need to be open for certificate generation

### Access From Outside (Twingate)

When you're away from home, connect via Twingate VPN. Once connected:

- Your device can route to your local IP (192.168.x.x)
- The same `*.home.yourdomain.com` URLs work everywhere
- No need to remember IPs or different URLs for home vs. away
- Full HTTPS with valid certificates

This gives you one consistent experience: same URLs, same bookmarks, whether you're on your couch or in a coffee shop.

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
