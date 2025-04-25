## 1. Clone the Repository:
```bash
git clone https://github.com/martin-gomola/pi-commander.git
cd pi-commander
```

## 2. Make setup files executable:
```bash
chmod +x install.sh
chmod +x setup/*.sh
```

## 3. Run the installation scripts:
```bash
sudo ./install.sh
```

## 4. Access Services:
```bash
Portainer: http://<your-pi-ip>:9000
Pi-hole: http://<your-pi-ip>:8080/admin
Nginx Proxy Manager: http://<your-pi-ip>:81
Streamlit App: http://<your-pi-ip>:8501
```

## Folder structure:
```
raspberry-pi-setup/
├── README.md
├── install.sh
├── setup/
│   ├── install_docker.sh
│   ├── install_docker_compose.sh
│   ├── setup_portainer.sh
│   ├── setup_pihole.sh
│   ├── setup_nginx_proxy_manager.sh
│   ├── setup_duckdns.sh
│   ├── setup_cronjob.sh
│   ├── setup_streamlit.sh
│   └── cleanup.sh
├── docker/
│   ├── portainer/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   ├── pihole/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   ├── nginx-proxy-manager/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   └── streamlit_app/
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── app.py
│       ├── requirements.txt
│       ├── views/
│       │   ├── __init__.py
│       │   ├── dividends.py
│       │   ├── espp_report.py
│       │   ├── travel_planner.py
│       │   └── config.json
│       ├── utils/
│       │   ├── __init__.py
│       │   └── data_processing.py
│       └── assets/
│           └── custom.css
└── config/
    ├── duckdns-update.sh
    └── nginx/
        ├── default.conf
        └── custom.conf
```