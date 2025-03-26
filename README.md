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
```bash
sudo nano /etc/nginx/sites-available/nginx.conf

sudo rm /etc/nginx/sites-enabled/nginx.conf
sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx
```


### Project Structure

```
.github/
└── workflows/
    ├── backup-affine.yml
    ├── deploy-affine.yml
    ├── deploy-streamlit.yml
    ├── renew-ssl.yml        # SSL certificate renewal
    ├── server-setup.yml     # Initial server setup
    └── setup-ssl.yml        # SSL configuration

affine_app/
├── docker-compose.yml       # Docker configuration for AFFiNE
├── data/                    # Persistent storage (database & uploads)
│   ├── uploads/             # AFFiNE file uploads
│   ├── config/              # AFFiNE configuration files
│   └── db/                  # PostgreSQL database storage
├── backup/
│   ├── affine-backup.sh           # Script to create backups
│   ├── affine-cleanup.sh          # Script to delete backups older than 30 days
│   ├── affine-restore-appdata.sh  # Restore AFFiNE application data
│   ├── affine-restore-db.sh       # Restore database
│   ├── backup-cronjob.sh          # (Optional) Automate backups with cron

streamlit_app/                   # Streamlit Dividend Tracker
├── assets/
│   ├── custom.css
│   └── tmp/
├── utils/
│   ├── __init__.py
│   └── data_processing.py
├── views/
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
### How to Restore from Backup?
To manually restore:

cd /srv/affine/backup
./affine-restore-appdata.sh
./affine-restore-db.sh


### Notes
Streamlit is set to run on port 8501, and the reverse proxy is configured to serve it at /divvy/.

Secure the .env File
Make sure the .env file is readable only by the owner to avoid security risks:
```bash
chmod 600 /srv/backups/.env
```

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
```bash
docker compose up --build --force-recreate -d
```


If UFW is active, run:

sudo ufw allow 587/tcp
sudo ufw allow 465/tcp
sudo ufw reload
Then verify:

sudo ufw status

--------
1️⃣ Add Swap Space (2GB)

Since your VM has only 1GB of RAM, adding swap will help prevent out-of-memory (OOM) crashes.

Create & Enable a 2GB Swap File
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
Make Swap Permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
Optimize Swap Settings
Edit /etc/sysctl.conf to reduce swap usage (prevents performance lag):

echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
2️⃣ Disable Unnecessary Services

Minimal Ubuntu is already lightweight, but you can further optimize it.

Disable Unused Services
```bash
sudo systemctl disable --now snapd lxd motd-news.timer
sudo apt remove --purge -y snapd lxd
```
Reduce Background Processes
```bash
sudo systemctl disable --now apport
sudo systemctl mask systemd-journald.service
```
3️⃣ Optimize PostgreSQL for Low RAM

PostgreSQL is memory-intensive. Adjust settings for low RAM.

Edit PostgreSQL Config File
```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```
Apply These Changes
# Reduce memory usage
```bash
shared_buffers = 128MB
work_mem = 16MB
maintenance_work_mem = 32MB
effective_cache_size = 256MB

# Reduce background processes
max_connections = 20
autovacuum = off
fsync = off
synchronous_commit = off
Restart PostgreSQL
sudo systemctl restart postgresql
```
4️⃣ Optimize Node.js for Low Memory

Affine runs on Node.js, which can consume a lot of RAM.

Limit Node.js Memory Usage
Run Affine with:
```bash
NODE_OPTIONS="--max-old-space-size=256" yarn start
```
5️⃣ Final Checks

Monitor RAM & Swap Usage
```bash
free -h
vmstat 5
```
Check if PostgreSQL is running efficiently
```bash
sudo -u postgres psql -c "SHOW work_mem;"
```


----File size ----
```bash
ls -lh /srv/backups
du -sh /srv/backups/*
```