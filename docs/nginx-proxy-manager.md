# Nginx Proxy Manager Setup

Quick reference for configuring proxy hosts and SSL certificates.

## First-Time Setup

1. Access NPM: `http://<YOUR_SERVER_IP>:81`
2. Default login: `admin@example.com` / `changeme`
3. Change password
4. Create your own admin user
5. Delete default admin

---

## SSL Certificate (Do This First)

### Wildcard Certificate

1. Go to **SSL Certificates** → **Add SSL Certificate**
2. Select **Let's Encrypt**
3. Domain names: `*.yourdomain.com`, `yourdomain.com`
4. Use **DNS Challenge**:
   - Provider: Cloudflare
   - API Token: Your Cloudflare token
   - Propagation: 120 seconds

---

## Creating Proxy Hosts

### Basic Template

For each service you want to expose:

1. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
2. Configure:
   - **Domain**: `service.yourdomain.com`
   - **Scheme**: `http`
   - **Forward Host**: `<YOUR_SERVER_IP>` or container name
   - **Forward Port**: Service port (e.g., 3001 for AdGuard)
3. SSL tab:
   - **Certificate**: `*.yourdomain.com`
   - **Force SSL**: Yes
   - **HTTP/2 Support**: Yes

### Example Hosts

| Subdomain | Forward Port | Service |
|-----------|--------------|---------|
| `dns.yourdomain.com` | 3001 | AdGuard Home |

---

## Common Configurations

### Websocket Support (for real-time services)

In **Advanced** tab, add:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Large File Uploads

```nginx
client_max_body_size 100M;
proxy_read_timeout 300;
```

---

## Troubleshooting

### Certificate Won't Generate
- Ensure ports 80/443 are open from internet
- Temporarily disable Cloudflare proxy (gray cloud)
- Check Let's Encrypt rate limits (5 per week per domain)

### Service Not Accessible
```bash
# Check service is running
docker ps | grep <service>

# Test direct access
curl http://<SERVER_IP>:<port>
```

### View Logs
```bash
docker logs nginx-proxy-manager --tail 50
```

---

## Maintenance

### Backup Before Changes
```bash
make backup-ssl
```

### Check Certificate Expiry
NPM auto-renews Let's Encrypt certs. Check in SSL Certificates tab.

### Update NPM
```bash
make update-service SERVICE=nginx-proxy-manager
```
