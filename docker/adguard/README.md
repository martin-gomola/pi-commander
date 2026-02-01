# AdGuard Home

DNS server with ad-blocking for your **local network**.

## Purpose

- Block ads and trackers on all devices at home
- Custom DNS filtering rules
- DNS-over-HTTPS (DoH) and DNS-over-TLS (DoT) support
- Query logging and statistics

## Quick Start

```bash
# Setup configuration
cd docker/adguard
cp .env.example .env
nano .env

# Deploy
docker-compose up -d

# Or use Makefile
make update-service SERVICE=adguard
```

## Configuration

### Initial Setup

1. Visit: `http://YOUR_SERVER_IP:3004`
2. Complete the setup wizard
3. Set admin credentials
4. Configure upstream DNS servers

### Recommended Settings

**Upstream DNS Servers:**
- Cloudflare: `1.1.1.1`, `1.0.0.1`
- Google: `8.8.8.8`, `8.8.4.4`
- Quad9: `9.9.9.9`

**Blocklists** (already enabled by default):
- AdGuard DNS filter
- Additional lists can be added in Settings → Filters

### Set as Network DNS

**Option 1: Router Configuration** (Recommended)
1. Access your router admin panel
2. Find DHCP/DNS settings
3. Set Primary DNS to your server IP: `192.168.1.190`
4. Save and reboot router

**Option 2: Per-Device**
Set DNS manually on each device to `192.168.1.190`

## Ports

- `53/tcp` `53/udp` - DNS queries
- `3001/tcp` - Web interface
- `3004/tcp` - Initial setup wizard
- `443/tcp` (`8443` externally) - DNS-over-HTTPS
- `853/tcp` - DNS-over-TLS

## Troubleshooting

**DNS not working:**
```bash
# Test DNS resolution
dig @192.168.1.190 google.com

# Check logs
docker logs adguard-home

# Restart service
docker-compose restart
```

**Web interface not accessible:**
- Check firewall rules
- Verify port 3001 is not blocked
- Try accessing via IP instead of hostname

## Learn More

- [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)
- [Official Documentation](https://github.com/AdguardTeam/AdGuardHome/wiki)
