# Tailscale

Private remote access and DNS routing for your homelab.

## Purpose

- Access homelab services securely from phone/laptop
- Route DNS to AdGuard Home without sending all traffic through home
- Avoid opening extra inbound ports

## Quick Start

```bash
# Setup configuration
cd docker/tailscale
cp .env.example .env
nano .env

# Deploy
docker compose up -d

# Or from repo root
make update-service SERVICE=tailscale
```

## Configuration

### 1. Create Tailscale Account + Auth Key

1. Visit [Tailscale Admin](https://login.tailscale.com/admin/machines)
2. Create an auth key: **Settings** → **Keys**
3. Add values to `.env`:
   ```bash
   TAILSCALE_AUTHKEY=tskey-auth-xxxxxxxx
   TAILSCALE_HOSTNAME=pi-commander
   TAILSCALE_EXTRA_ARGS=--accept-dns=true --advertise-routes=192.168.1.0/24
   ```

### 2. Deploy and Approve Subnet Route

1. Start container: `docker compose up -d`
2. In Tailscale admin, open the `pi-commander` machine
3. Approve advertised subnet routes

### 3. DNS via AdGuard

In Tailscale admin:

1. Open **DNS**
2. Add AdGuard private IP as nameserver (example: `192.168.1.190`)
3. Keep exit node disabled for DNS-only behavior

## Network Mode

Runs with `network_mode: host` and advertises your LAN subnet through Tailscale.

## Monitoring

```bash
# Container logs
docker logs tailscale --tail 50

# Interactive CLI inside container
docker exec -it tailscale tailscale status
```

## Troubleshooting

**Container is up but subnet route does not work:**

- Confirm route is approved in Tailscale admin
- Verify `TAILSCALE_EXTRA_ARGS` subnet matches your LAN
- Restart container after `.env` changes: `docker compose restart`

**DNS not using AdGuard on remote device:**

- Confirm AdGuard IP is reachable over advertised subnet
- Check Tailscale DNS settings and client DNS enabled
- Ensure exit node is not forced unless intentionally used

## Learn More

- [Tailscale Docs](https://tailscale.com/kb)
