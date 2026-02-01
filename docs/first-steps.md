# First Steps After Installation

Post-installation configuration.

💡 **Remote Access Tip:** Enable SSH for easier management from another computer:
```bash
sudo apt install openssh-server
# Then connect: ssh username@server-ip
```

---

## ✅ Quick Validation (30 seconds)

Before configuration, verify everything is working:

```bash
cd ~/pi-commander
make health
```

**Expected output:**
```
✓ Docker running
✓ NPM Admin (81): OK
✓ AdGuard DNS (53): OK  
✓ AdGuard Web (3001): OK
```

✅ **All checks passing?** Continue below.  
❌ **Any failures?** See [Troubleshooting Guide](troubleshooting.md)

---

## ⏱️ 5-Minute Setup

### 1. Change Default NPM Password

1. Go to: `http://your-server-ip:81`
2. Login with:
   - Email: `admin@example.com`
   - Password: `changeme`
3. Click your email (top right) → "Edit Details"
4. Change email and password
5. Log out and log back in

---

### 2. Setup AdGuard Home

1. Go to: `http://your-server-ip:3001`
2. Click "Get Started"
3. Leave ports as default → Next
4. Create your admin account
5. Skip the device setup (we'll do this later)

Now you have ad-blocking DNS. Configure devices to use it below.

---

## 🎯 What You Have Now

✅ Reverse proxy (NPM) for SSL and routing  
✅ Ad-blocking DNS (AdGuard)  
✅ Automatic container restarts  

Your server is **fully functional on your local network**.

**Want monitoring?** Check out [homelab-services](https://github.com/martin-gomola/homelab-services) for Uptime Kuma and other optional services.

---

## 🔒 Test Your Setup (Static Site + SSL)

**This validates that your entire infrastructure works end-to-end:**

### 0. Setup Static Homepage (First Time)

If you don't have a custom `static/index.html` yet:

```bash
cd ~/pi-commander
cp static/index.html.template static/index.html
```

This creates a beautiful status page. You can customize it later!

### 1. Add Your First Proxy Host in NPM

1. Go to NPM: `http://your-server-ip:81`
2. Click "Hosts" → "Proxy Hosts" → "Add Proxy Host"
3. Fill in:
   - **Domain Names:** `home.yourdomain.com` (or your DuckDNS domain)
   - **Scheme:** `http`
   - **Forward Hostname:** `nginx-proxy-manager`
   - **Forward Port:** `80`
   - **Block Common Exploits:** ✓ Enabled
   - **Websockets Support:** ✓ Enabled

4. Go to "SSL" tab:
   - **SSL Certificate:** Request a new SSL Certificate
   - **Force SSL:** ✓ Enabled
   - **Email:** Your email
   - **Agree to Let's Encrypt ToS:** ✓ Enabled
   - Click "Save"

### 2. Visit Your Site

Go to: `https://home.yourdomain.com`

**✅ Success looks like:**
- Beautiful status page loads
- Green lock icon in browser (valid SSL)
- All services show "✓ Running"

**This proves:**
- ✅ DNS is working (Cloudflare/DuckDNS)
- ✅ NPM reverse proxy works
- ✅ SSL certificates work
- ✅ Firewall allows 80/443
- ✅ Your domain points to your server

**🎉 If you see the status page with HTTPS, your infrastructure is production-ready!**

---

## 🌐 Optional: Internet Access

Want to access your server from anywhere? You need two things:

### Option 1: Cloudflare (Public Access)
**Best for:** Hosting websites, sharing services with friends

- Requires: A domain name ($10-15/year)
- Setup time: 15 minutes
- Guide: [Cloudflare Setup](cloudflare-setup.md)
- Result: Access via `https://service.yourdomain.com`

### Option 2: Twingate (Private VPN)
**Best for:** Personal secure access, no domain needed

- Requires: Free Twingate account
- Setup time: 10 minutes
- Guide: See `docker/twingate/.env` for configuration
- Result: Secure private access from anywhere

**Don't need internet access?** Skip both. Your server works on local network without them.

---

## 🏠 Using Your Server on Local Network

### Make Your Devices Use AdGuard DNS

**Method 1: Configure Your Router (Easiest)**
1. Log into your router admin panel
2. Find "DHCP Settings" or "DNS Settings"
3. Set Primary DNS to: `192.168.1.190` (your server IP)
4. Set Secondary DNS to: `8.8.8.8` (backup)
5. Save and reboot router

Now all devices on your network use AdGuard.

**Method 2: Configure Individual Devices**

**Windows:**
- Settings → Network → Change adapter options
- Right-click adapter → Properties
- Select "Internet Protocol Version 4"
- Use these DNS servers: `192.168.1.190` (primary), `8.8.8.8` (secondary)

**macOS:**
- System Preferences → Network
- Select connection → Advanced → DNS
- Add DNS Server: `192.168.1.190`

**iPhone/Android:**
- WiFi Settings → Configure DNS → Manual
- Add DNS: `192.168.1.190`

---

## 🚀 Next Level: Adding SSL Certificates

Want `https://` with a green lock?

### For Local Network (Self-Signed)
NPM can generate self-signed certificates (browsers will show a certificate warning, but traffic is encrypted).

### For Internet Access (Let's Encrypt)
After setting up Cloudflare, NPM can get free trusted SSL certificates automatically!

**Guide:** [Nginx Proxy Manager SSL Setup](nginx-proxy-manager.md#ssl-certificates)

---

## 📋 Daily Operations

### Check if Everything is Running
```bash
cd ~/pi-commander
make status
```

### Check Service Health
```bash
make health
```

### View Container Logs
```bash
cd ~/pi-commander
make lazydocker
```

### Update Containers
```bash
cd ~/pi-commander
make update
```

---

## 🆘 Something Not Working?

**Service won't load:**
```bash
cd ~/pi-commander
docker logs <container-name> --tail 50
```

**Full diagnostics:**
```bash
cd ~/pi-commander
./scripts/diagnostics.sh > diag.txt
```

**Common Issues:**
- See [Troubleshooting Guide](troubleshooting.md)
- Check container status: `docker ps`
- Restart a service: `cd ~/pi-commander/docker/<service> && docker-compose restart`

---

## 🎓 Learn More

**What each service does:**
- **Nginx Proxy Manager**: Routes traffic to the right place, handles SSL
- **AdGuard Home**: Blocks ads and trackers at the DNS level
- **Twingate**: Secure VPN for remote access (optional)
- **Cloudflare DDNS**: Keeps your domain pointing to your home IP (optional)

**Key files:**
- `docker/*/.env` - Service configurations
- `Makefile` - Automation commands
- `docker/*/docker-compose.yml` - Service definitions

**Architecture:**
All services run in Docker containers. They auto-start on boot and auto-restart if they crash. NPM runs on ports 80/443 and routes traffic internally to other services.

---

## You're Done

Your homelab is configured. Here's what you can do next:

1. Add proxy hosts in NPM
2. Review blocked queries in AdGuard
3. Add more services from [homelab-services](https://github.com/martin-gomola/homelab-services)

**Need help?** Check [Documentation Index](README.md) or [Troubleshooting](troubleshooting.md)
