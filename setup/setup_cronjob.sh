#!/bin/bash
# Setup cron job for DuckDNS
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/pi/duckdns/duckdns-update.sh >/dev/null 2>&1") | crontab -
