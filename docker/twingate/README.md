# Twingate Connector

Zero-trust VPN connector for secure remote access to your home network.

## Purpose

- Access home network resources remotely (web interfaces, services)
- Secure alternative to traditional VPN
- Works on cellular data (no router configuration needed)
- Connect to your home server from anywhere

## Quick Start

```bash
# Setup configuration
cd docker/twingate
cp .env.example .env
nano .env

# Deploy
docker-compose up -d

# Or use Makefile
make update-service SERVICE=twingate
```

## Configuration

### 1. Create Twingate Account

1. Visit: [https://twingate.com/signup](https://twingate.com/signup)
2. Create your network (e.g., `yourname-homelab`)
3. Install Twingate app on your mobile device

### 2. Create Connector Tokens

In Twingate Admin Console:

1. Go to **Connectors** → **Add Connector**
2. Name it: `pi-plane`
3. Generate tokens
4. Add to `.env`:
   ```bash
   TWINGATE_NETWORK=yourname-homelab.twingate.com
   TWINGATE_ACCESS_TOKEN=your_access_token
   TWINGATE_REFRESH_TOKEN=your_refresh_token
   ```

### 3. Create Resources

Resources define what you can access. Create these:

**AdGuard Admin** (if needed remotely):
- Name: `AdGuard Home`
- Address: `192.168.1.190`
- Protocol: HTTP
- Port: `3001`

**Nginx Proxy Manager**:
- Name: `Nginx Proxy Manager`
- Address: `192.168.1.190`
- Protocol: HTTP
- Port: `81`

**Your Apps** (add as needed):
- Create Resources for each service you want to access remotely

## Network Mode

This connector uses **host networking** (`network_mode: host`):
- Direct access to your local network
- Simpler routing for home network resources
- No need for port mapping

## Ports

None exposed - uses host networking and connects out to Twingate cloud.

## Monitoring

```bash
# Check connector status
docker logs twingate-connector

# Should show:
# State: Online
```

## Troubleshooting

**Connector offline:**
```bash
# Check logs
docker logs twingate-connector --tail 50

# Restart
docker-compose restart

# Verify tokens in .env
```

**Can't access resources:**
- Verify Resource is created in Twingate Console
- Check Access Policy allows your device
- Ensure connector is "Online" in Console

## Architecture

```
Mobile Device (Cellular)
    ↓
Twingate Cloud (VPN tunnel)
    ↓
Twingate Connector (Docker, Host Mode)
    ↓
Local Network Resources (192.168.1.x)
```

## Learn More

- [Twingate Documentation](https://twingate.com/docs)
