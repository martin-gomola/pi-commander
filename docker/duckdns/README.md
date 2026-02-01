# DuckDNS - Free Dynamic DNS

Free dynamic DNS service that provides you with a subdomain under `duckdns.org`.

## Why DuckDNS?

**Perfect for:**
- Testing before buying a domain
- Personal projects without public branding
- Users who don't want to pay $10-15/year for a domain

**You get:**
- Free subdomain: `yourusername.duckdns.org`
- Automatic IP updates
- Works with Let's Encrypt SSL certificates
- No registration fees

## Setup

### 1. Get Your DuckDNS Token

1. Go to: https://www.duckdns.org
2. Sign in with GitHub, Google, or other provider
3. Create your subdomain (e.g., `myhomelab`)
4. Copy your token

### 2. Configure DuckDNS

Edit `docker/duckdns/.env`:

```bash
DUCKDNS_SUBDOMAIN=myhomelab
DUCKDNS_TOKEN=your-token-here
TZ=Europe/Bratislava
```

### 3. Deploy

```bash
cd ~/pi-commander
make deploy-all
```

DuckDNS will update your IP every 5 minutes automatically.

### 4. Verify

Check your subdomain resolves to your IP:

```bash
nslookup myhomelab.duckdns.org
```

## Usage with Nginx Proxy Manager

When adding proxy hosts in NPM, use your DuckDNS domain:

**Domain Name:** `myhomelab.duckdns.org` or `*.myhomelab.duckdns.org` (for subdomains)

NPM can request Let's Encrypt SSL certificates for DuckDNS domains automatically.

## Container Management

**View logs:**
```bash
docker logs duckdns
```

**Check status:**
```bash
docker ps | grep duckdns
```

**Restart:**
```bash
cd docker/duckdns && docker compose restart
```

## Switching to Cloudflare Later

If you buy a domain later:

1. Stop DuckDNS: `cd docker/duckdns && docker compose down`
2. Configure Cloudflare DDNS (see [Cloudflare Setup](../docs/cloudflare-setup.md))
3. Update NPM proxy hosts with new domain
4. Request new SSL certificates

## Troubleshooting

**IP not updating:**

Check logs:
```bash
docker logs duckdns --tail 50
```

**Common issues:**
- Invalid token
- Subdomain already taken
- Network connectivity issues

**Force update:**
```bash
cd docker/duckdns && docker compose restart
```

## Limitations

**DuckDNS is free, but:**
- Subdomain is under `duckdns.org` (not fully custom)
- Subject to DuckDNS availability
- Not suitable for professional/commercial use

**For production or business use, consider:**
- Buying a domain ($10-15/year)
- Using Cloudflare for DNS management
- See [Cloudflare Setup Guide](../docs/cloudflare-setup.md)
