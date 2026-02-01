# Cloudflare Setup Guide

Set up Cloudflare for DNS management and dynamic DNS updates.

## Prerequisites

- Domain name (e.g., `yourdomain.com`)
- Free Cloudflare account (https://cloudflare.com)

---

## Step 1: Add Domain to Cloudflare

1. Log in to Cloudflare
2. Click **Add a Site**
3. Enter your domain name
4. Select **Free** plan
5. Cloudflare will scan existing DNS records

---

## Step 2: Update Nameservers

Cloudflare will provide nameservers like:
- `anna.ns.cloudflare.com`
- `bob.ns.cloudflare.com`

At your domain registrar:
1. Find DNS/Nameserver settings
2. Replace existing nameservers with Cloudflare's
3. Save changes (propagation takes 1-24 hours)

---

## Step 3: Configure DNS Records

### Required Records

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | @ | `<YOUR_SERVER_IP>` | Proxied (orange) |
| A | * | `<YOUR_SERVER_IP>` | DNS only (gray) |
| CNAME | www | yourdomain.com | Proxied |

**Note:** Wildcard records can't be proxied on free plan.

---

## Step 4: Create API Token

For DDNS updates:

1. Go to **My Profile** → **API Tokens**
2. Click **Create Token**
3. Use **Edit zone DNS** template, or create custom:
   - Zone > DNS > Edit
   - Zone > Zone > Read
4. Zone Resources: Include your domain
5. Copy token (you won't see it again)

### Test Token

```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Step 5: Configure Pi-Commander

Edit `docker/cloudflare-ddns/.env`:

```env
CLOUDFLARE_API_TOKEN=<YOUR_TOKEN>
CLOUDFLARE_DOMAINS=yourdomain.com,www.yourdomain.com,*.yourdomain.com
```

---

## Step 6: Deploy DDNS

```bash
cd ~/pi-commander
make deploy-all

# Verify
docker logs cloudflare-ddns
```

Should show:
```
INFO: yourdomain.com updated to X.X.X.X
```

---

## SSL/TLS Settings

In Cloudflare Dashboard:

**SSL/TLS → Overview:**
- Mode: **Full (strict)** (recommended)

**SSL/TLS → Edge Certificates:**
- Always Use HTTPS: On
- Minimum TLS Version: TLS 1.2

---

## Troubleshooting

### DDNS Not Updating

```bash
# Check logs
docker logs cloudflare-ddns --tail 50

# Common issues:
# - Invalid API token
# - Wrong domain in config
# - Domain not active on Cloudflare
```

### DNS Propagation Check

Visit https://www.whatsmydns.net/

### 522 Connection Timed Out

Cloudflare can't reach your server:
- Check firewall allows ports 80/443
- Verify IP address in Cloudflare matches server

---

## Useful Commands

```bash
# Check DDNS status
docker logs cloudflare-ddns

# Test DNS resolution
dig yourdomain.com +short
dig @1.1.1.1 yourdomain.com +short

# Restart DDNS
docker restart cloudflare-ddns
```
