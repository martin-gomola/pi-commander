#!/bin/bash
# Full Setup Script for Raspberry Pi

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Error: .env file not found. Please create it before running this script."
  exit 1
fi

# Update the system
sudo apt update && sudo apt upgrade -y

# Run all the setup scripts
sudo bash setup/install_docker.sh
sudo bash setup/install_docker_compose.sh
sudo bash setup/setup_portainer.sh
sudo bash setup/setup_pihole.sh
sudo bash setup/setup_nginx_proxy_manager.sh
sudo bash setup/setup_duckdns.sh
sudo bash setup/setup_cronjob.sh
sudo bash setup/setup_streamlit.sh

echo "Setup complete! Please access the services at their respective ports."
echo "Portainer: http://<your_pi_ip>:9000"
echo "Pi-hole: http://<your_pi_ip>/admin"
echo "Nginx Proxy Manager: http://<your_pi_ip>:81"
echo "DuckDNS: http://<your_duckdns_domain>"
echo "Cronjob: Check your email for the cronjob output."