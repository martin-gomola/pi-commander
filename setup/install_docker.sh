#!/bin/bash
# Update and install Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
