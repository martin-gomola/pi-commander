# Setup Guide

Your server is installed. Now configure it.

## Verify Installation

Run this to check everything works:

```bash
cd ~/pi-commander
make health
```

You should see:
```
✓ Docker running
✓ NPM Admin (81): OK
✓ AdGuard DNS (53): OK
✓ AdGuard Web (3001): OK
```

All green? Continue below. Something failed? See [Troubleshooting](troubleshooting.md).

---

## Configure Services

### 1. Change NPM Default Password

The admin panel uses insecure defaults. Change them now.

1. Open `http://your-server-ip:81`
2. Log in with `admin@example.com` / `changeme`
3. Click your email (top right) → Edit Details
4. Set your real email and a strong password
5. Log out and back in

### 2. Set Up AdGuard Home

AdGuard blocks ads and trackers for your entire network.

1. Open `http://your-server-ip:3001`
2. Click "Get Started"
3. Keep default ports, click Next
4. Create your admin account
5. Skip device setup for now

You now have network-wide ad blocking.

---

## Configure Devices to Use AdGuard

Point your devices to your server's DNS.

### Option A: Router (All Devices)

1. Open your router admin (usually `192.168.1.1`)
2. Find DNS settings
3. Set primary DNS: `your-server-ip`
4. Set secondary DNS: `8.8.8.8` (fallback)
5. Save and reboot router

Every device on your network now uses AdGuard.

### Option B: Individual Devices

**Windows:** Settings → Network → Change adapter → IPv4 → DNS: `your-server-ip`

**macOS:** System Preferences → Network → Advanced → DNS → Add `your-server-ip`

**iOS:** Settings → Wi-Fi → (i) → Configure DNS → Manual → Add `your-server-ip`

**Android:** Settings → Wi-Fi → Long press network → Modify → DNS 1: `your-server-ip`

---

## Test Ad Blocking

1. Open `http://your-server-ip:3001`
2. Watch the dashboard
3. Browse a website with ads
4. Refresh dashboard - blocked count should increase

---

## Internet Access (Optional)

Your server works on local network. To access from anywhere, choose one:

**How DDNS Works:** Most home internet has a changing IP address. Pi-Commander includes DDNS containers (Cloudflare or DuckDNS) that automatically update your domain when your IP changes. You configure it once, and it keeps working.

### Cloudflare (With Your Own Domain)

Best for: Professional setup, hosting websites

- Requires: Domain name (yourdomain.com)
- Setup time: 15 minutes
- Result: `https://service.yourdomain.com`

See [Services Guide](services.md#cloudflare-ddns) for setup.

### DuckDNS (Free Alternative)

Best for: Personal use, no domain needed

- Requires: Free DuckDNS account
- Setup time: 5 minutes
- Result: `https://yourname.duckdns.org`

See [Services Guide](services.md#duckdns-alternative-to-cloudflare) for setup.

### Twingate (Private VPN)

Best for: Personal access only, no domain needed

- Requires: Free Twingate account
- Setup time: 10 minutes
- Result: Secure private access from anywhere

See [Services Guide](services.md#twingate-vpn) for setup.

### Skip Both

Your server works fine locally. Set up internet access later when you need it.

---

## Test SSL (If Using Cloudflare)

After configuring Cloudflare, verify your setup:

1. Create a test page:
   ```bash
   cd ~/pi-commander
   cp static/index.html.template static/index.html
   ```

2. Add proxy host in NPM:
   - Domain: `home.yourdomain.com`
   - Forward to: `your-server-ip:80`
   - Enable SSL with Let's Encrypt

3. Visit `https://home.yourdomain.com`

Green lock icon? Your infrastructure works.

---

## Useful Commands

```bash
make status          # Check system status
make health          # Run health checks
make logs            # View all logs
make help            # Show all commands
lazydocker           # Docker UI
```

---

## Automated Tasks (Cron Jobs)

Set up automated backups and maintenance.

### Weekly Backups

```bash
make backup-cron-setup
```

Runs every Sunday at 2 AM. Backs up:
- All Docker service data (`/srv/docker/`)
- SSL certificates and NPM database

Backups stored in `/srv/backups/` with 7-week retention.

### Weekly Reboot (Optional)

```bash
make reboot-cron-setup
```

Reboots server every Sunday at 4 AM. Keeps things fresh.

### Check Scheduled Tasks

```bash
make cron-status
```

### Remove Cron Jobs

```bash
make backup-cron-remove
make reboot-cron-remove
```

### Manual Backup

Run anytime:

```bash
make backup           # Full backup
make backup-ssl       # SSL certificates only
```

---

## What You Have Now

- Reverse proxy with SSL (NPM)
- Network-wide ad blocking (AdGuard)
- Automatic container restarts
- Backup scripts ready

---

## Next Steps

- [Services Guide](services.md) - Configure Cloudflare, Twingate, SSL
- [Troubleshooting](troubleshooting.md) - Fix common issues
- [homelab-services](https://github.com/martin-gomola/homelab-services) - Add more apps
