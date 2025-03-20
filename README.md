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
sudo nano /etc/nginx/sites-available/nginx.conf

sudo rm /etc/nginx/sites-enabled/nginx.conf
sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx



Project Structure

```
.github/
└── workflows/
    ├── deploy-affine.yml    # GitHub Actions workflow for deployment
    ├── deploy-streamlit.yml # GitHub Actions workflow for deployment
    ├── renew-ssl.yml        # SSL certificate renewal
    ├── server-setup.yml     # Initial server setup
    └── setup-ssl.yml        # SSL configuration

affine/                      # AFFiNE Self-Hosted
├── docker-compose.yml       # Docker configuration for AFFiNE
├── data/                    # Persistent storage (database & uploads)
│   ├── uploads/             # AFFiNE file uploads
│   ├── config/              # AFFiNE configuration files
│   └── db/                  # PostgreSQL database storage

streamlit_app/                   # Streamlit Dividend Tracker
├── assets/
│   ├── custom.css
│   └── tmp/
├── utils/
│   ├── __pycache__/
│   ├── __init__.py
│   └── data_processing.py
├── views/
│   ├── __pycache__/
│   ├── __init__.py
│   ├── config.json
│   ├── dividends.py
│   ├── espp_report.py
│   └── travel_planner.py
├── docker-compose.yml       # Docker configuration for Streamlit
├── Dockerfile
├── app.py                   # Streamlit app entry point
├── requirements.txt         # Python dependencies
├── nginx/
│   └── nginx.conf           # Nginx config
├── static/
│   ├── 404.html
│   └── index.html           # Static HTML file for Nginx root
└── terraform-oci/           # Terraform setup for Oracle Cloud
.gitignore
README.md
```

Notes
Streamlit is set to run on port 8501, and the reverse proxy is configured to serve it at /divvy/.

Affine:
Have done email sending to work as follow:

Do not make any changes in the affine.env.js file
Make sure the following variables are set in the compose.yml file at the environment section:
- MAILER_HOST=smtp.domain.com
- MAILER_PORT=587
- MAILER_USER=your_user@domain.com
- MAILER_PASSWORD=your_user_password
- MAILER_SENDER=your_user@domain.com
Be sure to use the app password, not the normal one.
3. Recreate the container with the command 
```
docker compose up --build --force-recreate -d
```


If UFW is active, run:

sudo ufw allow 587/tcp
sudo ufw allow 465/tcp
sudo ufw reload
Then verify:

sudo ufw status