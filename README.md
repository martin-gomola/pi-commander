# Streamlit Deployment on Oracle Cloud

This repository contains the configuration files and setup for deploying a Streamlit app on an Oracle Cloud instance using Nginx as a reverse proxy.

## Useful Server Commands

### SSH to the Server
To SSH into your server, run the following command:
```bash
ssh <USERNAME>@<HOST>
Replace <USERNAME> with your server's username and <HOST> with the server's IP address or hostname.
```
Restart Nginx
If you need to restart Nginx after updating configurations or to ensure it's running correctly, use the following command:
```bash
sudo systemctl restart nginx
```
Check Nginx Status
To check the status of Nginx, use:
```bash
sudo systemctl status nginx
```
Check Streamlit Service Status
To check if the Streamlit app is running correctly, use:
```bash
sudo systemctl status streamlit.service
```
Check Streamlit Logs
To view Streamlit logs and diagnose issues, you can use:
```bash
journalctl -u streamlit.service
```
Test Nginx Configuration
Before restarting Nginx, it's a good idea to test the configuration to ensure there are no syntax errors:
```bash
sudo nginx -t
```
Enable/Disable Nginx at Boot
To enable Nginx to start on boot, run:
```bash
sudo systemctl enable nginx
```
To disable Nginx from starting at boot, run:
```bash
sudo systemctl disable nginx
```
Streamlit Logs
If you need to check logs for Streamlit specifically, you can find them in the journal logs:
```bash
sudo journalctl -u streamlit.service --no-pager --lines=50

sudo journalctl -u nginx --no-pager --lines=50
```
Viewing Server Disk Space
To check disk space usage on the server:
```bash
df -h
```
Viewing Server Memory Usage
To check memory usage on the server:
```bash
free -h
```
Viewing Active Connections
To view active network connections:
```bash
sudo netstat -tulnp
```
Reboot the Server
If needed, you can reboot the server with:
```bash
sudo reboot
```
Update the Server
To update the server's package list and upgrade all installed packages:
```bash
sudo apt update && sudo apt upgrade -y
```
Install a Package
To install any package on the server (for example, htop to monitor system processes):
```bash
sudo apt install htop
```

 Edit the Nginx configuration file:
sudo nano /etc/nginx/sites-available/streamlit.conf

sudo rm /etc/nginx/sites-enabled/streamlit.conf
sudo ln -s /etc/nginx/sites-available/streamlit.conf /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx



Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions Deployment Workflow
├── divvy_app/
│   ├── assets/
│   │   └── custom.css         # Custom CSS file
│   ├── views/
│   │   ├── __init__.py
│   │   ├── dividends.py       # 2024 Dividend Entry page
│   │   └── tax_report.py      # 2025 Tax Report page
│   ├── utils/
│   │   ├── __init__.py
│   │   └── data_processing.py  # Functions for processing dividend data
│   ├── app.py                 # Main entry point for the Streamlit app
│   └── requirements.txt       # Python dependencies
├── nginx/
│   └── streamlit.conf         # Nginx configuration file
├── systemd/
│   └── streamlit.service      # Systemd service file for Streamlit
└── static/
    ├── 404.html
    └── index.html             # Static HTML file for Nginx root

```
Notes
Streamlit is set to run on port 8501, and the reverse proxy is configured to serve it at /divvy/.