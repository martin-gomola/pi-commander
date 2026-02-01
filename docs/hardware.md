# Hardware Reference

Quick reference for server hardware and resources.

## Check Your Hardware

```bash
# Quick summary
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "OS: $(lsb_release -d | cut -f2)"

# Detailed info
lscpu          # CPU
free -h        # Memory
df -h          # Storage
lsblk          # Disks
```

## Recommended Specs

| | Minimum | Recommended |
|---|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4GB | 8GB+ |
| Storage | 32GB | 128GB+ SSD |
| Network | 100Mbps | Gigabit |

## Storage Layout

```
/srv/docker/              # Docker service data
├── nginx-proxy-manager/
└── adguard/

/srv/backups/             # Automated backups

~/pi-commander/           # Git repository
└── docker/               # Docker Compose files
```

## Resource Monitoring

```bash
# Docker containers
docker stats --no-stream

# System overview
htop

# Disk usage
df -h
du -sh /srv/docker/*
```

## Suitable For

Pi-Commander works well for:
- Home server / NAS
- Docker containers (light to medium load)
- DNS, proxy, VPN services
- Development environments

Not recommended for:
- Heavy compute workloads
- Video transcoding
- Large-scale databases
