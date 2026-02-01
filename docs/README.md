# Documentation Guide

Welcome! This guide helps you find the right documentation for your needs.

## 🆕 New to Homelab? Start Here

**Just want to get started?** You only need these:

1. **[Quick Start](../README.md#quick-start-fresh-ubuntu-server)** - One command to install everything (5 min)
2. **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
3. **[First Steps After Install](first-steps.md)** - What to do after installation

That's it! You can skip everything else until you need it.

---

## 📚 Complete Documentation

### Getting Started
- **[Quick Start](../README.md#quick-start-fresh-ubuntu-server)** - One-command installation
- **[First Steps](first-steps.md)** - Essential setup after install
- **[Troubleshooting](troubleshooting.md)** - Common problems and solutions

### Service Setup
- **[Cloudflare Setup](cloudflare-setup.md)** - Domain and DDNS configuration (paid domain)
- **[DuckDNS Setup](../docker/duckdns/README.md)** - Free dynamic DNS alternative
- **[Nginx Proxy Manager](nginx-proxy-manager.md)** - Reverse proxy and SSL certificates

### Reference
- **[Port Mapping](port-mapping.md)** - All exposed ports and their services
- **[Scripts Guide](scripts-guide.md)** - Utility scripts reference
- **[Hardware Guide](hardware.md)** - System requirements and recommendations

### Advanced
- **[Advanced Installation](advanced-installation.md)** - Complete step-by-step walkthrough
- **[Updating Services](updating-services.md)** - How to update containers

---

## 🎯 Common Tasks

### "I just installed, what now?"
→ [First Steps](first-steps.md)

### "Something isn't working"
→ [Troubleshooting](troubleshooting.md)

### "I want to access services from the internet"
→ [Cloudflare Setup](cloudflare-setup.md) (paid domain)  
→ [DuckDNS Setup](../docker/duckdns/README.md) (free subdomain)

### "How do I add SSL certificates?"
→ [Nginx Proxy Manager](nginx-proxy-manager.md#ssl-certificates)

### "What are all these ports?"
→ [Port Mapping](port-mapping.md)

### "How do I update my containers?"
→ [Updating Services](updating-services.md)

---

## 💡 Tips

**For Beginners:**
- Start with Quick Start only
- Don't worry about Cloudflare/Twingate initially - your server works fine on local network
- Use Troubleshooting guide when something breaks
- Everything else is optional

**For Experts:**
- All source configs in `docker/*/docker-compose.yml`
- Service configs: `docker/*/.env`
- Scripts in `scripts/`
- Makefile has all automation
- See [Advanced Installation](advanced-installation.md) for architecture details

---

## 📖 Documentation Philosophy

We follow the [Divio Documentation System](https://documentation.divio.com/):

- **Tutorials** (Learning): Quick Start, First Steps
- **How-to Guides** (Problem-solving): Troubleshooting, Cloudflare Setup
- **Reference** (Information): Port Mapping, Scripts Guide
- **Explanation** (Understanding): Advanced Installation, Architecture

This structure ensures you can find what you need quickly, whether you're learning or looking up specific information.
