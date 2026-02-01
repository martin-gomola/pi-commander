# Static Files

This directory contains static files served by Nginx Proxy Manager.

## Files

### `index.html.template`
Default homepage template showing Pi-Commander status page.

**Usage:**
```bash
# First time setup (bootstrap does this automatically)
cp index.html.template index.html
```

### `index.html`
Your custom homepage. **This file is gitignored** so you can customize it per server without affecting the repository.

**Customize it:**
```bash
nano static/index.html
# Make your changes
# Changes stay local, won't be committed to git
```

### `404.html`
Default 404 error page served by NPM.

## Setting Up in NPM

1. Go to NPM Admin: `http://your-server-ip:81`
2. Hosts → Proxy Hosts → Add Proxy Host
3. Configure:
   - **Domain:** `home.yourdomain.com`
   - **Scheme:** `http`
   - **Forward Hostname:** `nginx-proxy-manager`
   - **Forward Port:** `80`
4. SSL Tab:
   - Request new SSL certificate
   - Enable "Force SSL"

## Directory Structure

```
/srv/docker/nginx-proxy-manager/data/
├── nginx/
│   └── proxy_host/
└── custom_ssl/

/Users/mgomola/dev/pi-commander/static/   (mounted read-only)
├── index.html.template    (tracked in git)
├── index.html            (gitignored, your custom version)
└── 404.html              (tracked in git)
```

## Tips

**Keep template updated:**
```bash
git pull  # Gets latest index.html.template
# Your index.html stays unchanged
```

**Start fresh from template:**
```bash
cp index.html.template index.html
```

**Backup your custom page:**
```bash
cp static/index.html ~/index.html.backup
```
