#!/bin/bash
# DuckDNS update script

# Set your DuckDNS token and domain
TOKEN="your-duckdns-token"
DOMAIN="matie"

# Update DuckDNS
curl "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip="
