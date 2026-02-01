# Nginx Proxy Manager Configuration

## Static Site Configuration

To serve static files from `/static` directory for martingomola.com:

### Proxy Host Setup

**Details Tab:**
- Domain Names: `martingomola.com`, `www.martingomola.com`
- Scheme: `http`
- Forward Hostname/IP: `localhost`
- Forward Port: `80`
- Cache Assets: ✓
- Block Common Exploits: ✓

**Custom Locations Tab:**

Add a custom location for `/` with this configuration:

```nginx
# Redirect www to non-www
if ($host = 'www.martingomola.com') {
    return 301 https://martingomola.com$request_uri;
}

location / {
    root /static;
    index index.html;
    try_files $uri $uri/ =404;
}
```

**SSL Tab:**
- SSL Certificate: Let's Encrypt
- Force SSL: ✓
- HTTP/2 Support: ✓
- HSTS Enabled: ✓
- Use DNS Challenge: ✓
- DNS Provider: Cloudflare
- Credentials:
```
dns_cloudflare_api_token=${CLOUDFLARE_API_TOKEN}
```

## Volume Mounts

The `docker compose.yml` mounts the static directory:
```yaml
volumes:
  - ../../static:/static:ro
```

Static files should be placed in `pi-commander/static/` directory.

## Cloudflare Configuration

- **SSL/TLS Mode**: Full (not Full Strict)
- **Proxy Status**: Enabled (orange cloud)
- **DDNS**: Managed by cloudflare-ddns container
