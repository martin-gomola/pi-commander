.PHONY: help deploy deploy-all status update update-service backup backup-ssl restore logs restart stop start health info commit

# Configuration
DEPLOY_SCRIPT := ./deploy-auto.sh
BACKUP_SCRIPT := ./scripts/backup-ssl-certs.sh
RESTORE_SCRIPT := ./scripts/restore-ssl-certs.sh
BACKUP_DIR := /srv/backups

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

.DEFAULT_GOAL := help

help: ## Display help
	@echo "$(GREEN)Pi-Commander - Core Infrastructure Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Main Commands:$(NC)"
	@echo "  $(GREEN)make deploy-all$(NC)            Deploy core infrastructure (NPM, DNS, VPN, DDNS)"
	@echo "  $(GREEN)make update$(NC)                Pull git & auto-deploy changed services"
	@echo "  $(GREEN)make update-service SERVICE=<name>$(NC)  Update specific service"
	@echo "  $(GREEN)make status$(NC)                Show git & container status"
	@echo ""
	@echo "$(YELLOW)Service Control:$(NC)"
	@echo "  $(GREEN)make restart$(NC)        Restart all services"
	@echo "  $(GREEN)make stop$(NC)           Stop all services"
	@echo "  $(GREEN)make start$(NC)          Start all services"
	@echo "  $(GREEN)make logs$(NC)           Show logs for all containers"
	@echo ""
	@echo "$(YELLOW)Backup & Maintenance:$(NC)"
	@echo "  $(GREEN)make backup$(NC)              Create full backup"
	@echo "  $(GREEN)make backup-ssl$(NC)          Backup SSL certificates only"
	@echo "  $(GREEN)make backup-cron-setup$(NC)   Setup weekly backups (Sunday 2 AM)"
	@echo "  $(GREEN)make reboot-cron-setup$(NC)   Setup weekly reboot (Sunday 4 AM)"
	@echo "  $(GREEN)make cron-status$(NC)         Show all scheduled tasks"
	@echo "  $(GREEN)make restore$(NC)             Restore from backup (use BACKUP_FILE=path)"
	@echo ""
	@echo "$(YELLOW)Monitoring:$(NC)"
	@echo "  $(GREEN)make health$(NC)         Run health checks"
	@echo "  $(GREEN)make info$(NC)           Show system information"
	@echo "  $(GREEN)make lazydocker$(NC)     Launch Docker terminal UI"
	@echo "  $(GREEN)make check-updates$(NC)  Check for container updates"
	@echo ""
	@echo "$(YELLOW)Troubleshooting:$(NC)"
	@echo "  $(GREEN)./scripts/diagnostics.sh$(NC)  Generate diagnostics report"
	@echo "  See docs/TROUBLESHOOTING.md for common issues"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  $(GREEN)make test-syntax$(NC)         Validate YAML syntax (no Docker needed)"
	@echo "  $(GREEN)make test-config$(NC)         Validate docker compose configs (needs Docker)"
	@echo "  $(GREEN)make test-dry-run$(NC)        Start/stop services to verify launch"
	@echo ""
	@echo "$(YELLOW)Git:$(NC)"
	@echo "  $(GREEN)make commit$(NC)              Commit changes (interactive)"
	@echo ""
	@echo "Looking for services? Check out:"
	@echo "  https://github.com/martin-gomola/homelab-services"
	@echo ""

##@ Deployment

deploy: ## Smart deploy (only changed services)
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT) deploy

update: deploy ## Alias for deploy (git pull + update services)

update-service: ## Update specific service (use: make update-service SERVICE=affine)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE$(NC)"; \
		echo "Usage: make update-service SERVICE=<service-name>"; \
		echo ""; \
		echo "Available services:"; \
		ls -1 docker/ | grep -v "^\."; \
		exit 1; \
	fi
	@if [ ! -d "docker/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service 'docker/$(SERVICE)' not found$(NC)"; \
		exit 1; \
	fi
	@echo "Updating $(SERVICE)..."
	@cd docker/$(SERVICE) && \
		docker compose pull && \
		docker compose up -d && \
		echo "$(GREEN)✓ $(SERVICE) updated$(NC)" && \
		docker compose ps

deploy-all: ## Deploy core infrastructure services
	@echo "Deploying core infrastructure services..."
	@echo ""
	@echo "[1/5] Deploying Nginx Proxy Manager..."
	@cd docker/nginx-proxy-manager && docker compose up -d
	@echo "[2/5] Deploying AdGuard Home..."
	@cd docker/adguard && docker compose up -d
	@echo "[3/5] Deploying Twingate Connector..."
	@cd docker/twingate && docker compose up -d
	@echo "[4/5] Deploying Dynamic DNS..."
	@if [ -f docker/cloudflare-ddns/.env ] && [ -s docker/cloudflare-ddns/.env ]; then \
		echo "  Using Cloudflare DDNS..."; \
		cd docker/cloudflare-ddns && docker compose up -d; \
	elif [ -f docker/duckdns/.env ] && [ -s docker/duckdns/.env ]; then \
		echo "  Using DuckDNS..."; \
		cd docker/duckdns && docker compose up -d; \
	else \
		echo "  $(YELLOW)No DDNS configured (optional)$(NC)"; \
	fi
	@echo "[5/5] Verifying deployments..."
	@sleep 3
	@echo ""
	@echo "$(GREEN)Core infrastructure deployed$(NC)"
	@echo ""
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

status: ## Show git and container status
	@chmod +x $(DEPLOY_SCRIPT)
	@$(DEPLOY_SCRIPT) status

##@ Service Control

restart: ## Restart all running containers
	@echo "Restarting all services..."
	@docker ps -q | xargs -r docker restart
	@echo "$(GREEN)All services restarted$(NC)"

stop: ## Stop all running containers
	@echo "Stopping all services..."
	@docker ps -q | xargs -r docker stop
	@echo "$(GREEN)All services stopped$(NC)"

start: ## Start all containers
	@echo "Starting all services..."
	@for dir in docker/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			cd "$$dir" && docker compose up -d && cd ../..; \
		fi \
	done
	@echo "$(GREEN)All services started$(NC)"

##@ Backup & Restore

backup: ## Create full backup of all data
	@echo "Creating full backup..."
	@sudo mkdir -p $(BACKUP_DIR)
	@sudo tar -czf $(BACKUP_DIR)/pi-commander-full-$$(date +%Y%m%d-%H%M%S).tar.gz \
		--exclude='*.log' \
		/srv/docker/nginx-proxy-manager/ \
		/srv/docker/adguard/ \
		$(HOME)/pi-commander/docker/*/.env \
		2>/dev/null || true
	@echo "$(GREEN)Backup complete$(NC)"
	@ls -lh $(BACKUP_DIR)/*.tar.gz | tail -1

backup-ssl: ## Backup SSL certificates only
	@echo "Backing up SSL certificates..."
	@chmod +x $(BACKUP_SCRIPT)
	@sudo $(BACKUP_SCRIPT)
	@echo "$(GREEN)SSL backup complete$(NC)"

restore: ## Restore from backup (use: make restore BACKUP_FILE=/path/to/backup.tar.gz)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: Please specify BACKUP_FILE$(NC)"; \
		echo "Usage: make restore BACKUP_FILE=/path/to/backup.tar.gz"; \
		ls -lh $(BACKUP_DIR)/*.tar.gz 2>/dev/null || true; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from $(BACKUP_FILE)...$(NC)"
	@$(MAKE) stop
	@sudo tar -xzf $(BACKUP_FILE) -C /
	@$(MAKE) start
	@echo "$(GREEN)Restore complete$(NC)"

restore-ssl: ## Restore SSL certificates (use: make restore-ssl BACKUP_FILE=/path/to/backup.tar.gz)
	@chmod +x $(RESTORE_SCRIPT)
	@sudo $(RESTORE_SCRIPT) $(BACKUP_FILE)

backup-cron-setup: ## Setup automated weekly backups (Sunday 2 AM)
	@echo "Setting up automated backups..."
	@chmod +x scripts/backup-cron.sh
	@(crontab -l 2>/dev/null | grep -v "backup-cron.sh"; echo "0 2 * * 0 $(CURDIR)/scripts/backup-cron.sh") | crontab -
	@echo "$(GREEN)Automated backup scheduled for Sunday 2 AM$(NC)"
	@echo "Current crontab:"
	@crontab -l | grep backup-cron || true

backup-cron-remove: ## Remove automated backup cron job
	@echo "Removing automated backup cron job..."
	@crontab -l 2>/dev/null | grep -v "backup-cron.sh" | crontab - || true
	@echo "$(GREEN)Automated backup removed$(NC)"

reboot-cron-setup: ## Setup weekly server reboot (Sunday 4 AM)
	@echo "Setting up weekly reboot schedule..."
	@(sudo crontab -l 2>/dev/null | grep -v "reboot"; echo "0 4 * * 0 /sbin/reboot") | sudo crontab -
	@echo "$(GREEN)Weekly reboot scheduled for Sunday 4 AM$(NC)"
	@echo "Root crontab:"
	@sudo crontab -l | grep reboot || true

reboot-cron-remove: ## Remove weekly reboot cron job
	@echo "Removing weekly reboot cron job..."
	@sudo crontab -l 2>/dev/null | grep -v "reboot" | sudo crontab - || true
	@echo "$(GREEN)Weekly reboot removed$(NC)"

cron-status: ## Show all scheduled cron jobs
	@echo "=== Scheduled Tasks ==="
	@echo ""
	@echo "User crontab:"
	@crontab -l 2>/dev/null || echo "  No user cron jobs"
	@echo ""
	@echo "Root crontab:"
	@sudo crontab -l 2>/dev/null || echo "  No root cron jobs"

##@ Monitoring & Logs

logs: ## Show logs for all containers
	@docker ps -q | xargs -I {} sh -c 'echo "=== $$(docker inspect --format="{{.Name}}" {}) ===" && docker logs --tail 20 {}'

logs-follow: ## Follow logs from all containers
	@docker compose logs -f

logs-npm: ## Show Nginx Proxy Manager logs
	@docker logs -f nginx-proxy-manager

logs-dns: ## Show AdGuard Home logs
	@docker logs -f adguard-home

logs-twingate: ## Show Twingate Connector logs
	@docker logs -f twingate-connector


health: ## Run comprehensive health checks
	@echo "=== System Health Check ==="
	@echo ""
	@echo "Docker Status:"
	@sudo systemctl is-active docker > /dev/null 2>&1 && echo "$(GREEN)✓ Docker running$(NC)" || echo "$(RED)✗ Docker not running$(NC)"
	@echo ""
	@echo "Running Containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}"
	@echo ""
	@echo "Service Health:"
	@printf "  NPM Admin (81):      "
	@curl -sf http://localhost:81/api > /dev/null 2>&1 && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ FAIL$(NC)"
	@printf "  AdGuard DNS (53):    "
	@dig @localhost google.com +short > /dev/null 2>&1 && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ FAIL$(NC)"
	@printf "  AdGuard Web (3001):  "
	@curl -sf http://localhost:3001 > /dev/null 2>&1 && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ FAIL$(NC)"
	@echo ""
	@echo "Disk Usage:"
	@df -h /srv/docker 2>/dev/null || df -h /
	@echo ""
	@echo "Memory Usage:"
	@free -h | grep -E "Mem|Swap"
	@echo ""

info: ## Show system and service information
	@echo "=== Pi-Commander System Info ==="
	@echo ""
	@echo "System:"
	@echo "  Hostname:   $$(hostname)"
	@echo "  IP Address: $$(hostname -I | awk '{print $$1}')"
	@echo "  OS:         $$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
	@echo "  Uptime:     $$(uptime -p)"
	@echo ""
	@echo "Repository:"
	@echo "  Branch:     $$(git branch --show-current)"
	@echo "  Commit:     $$(git rev-parse --short HEAD)"
	@echo ""
	@echo "Service URLs:"
	@echo "  NPM Admin:    http://$$(hostname -I | awk '{print $$1}'):81"
	@echo "  AdGuard:      http://$$(hostname -I | awk '{print $$1}'):3001"
	@echo ""

##@ Docker Management

lazydocker: ## Launch lazydocker terminal UI
	@lazydocker

check-updates: ## Check for container updates (dockcheck)
	@dockcheck.sh

check-updates-notify: ## Check updates with notifications
	@dockcheck.sh -n

##@ Testing

test-syntax: ## Validate YAML syntax (no Docker required)
	@echo "Validating YAML syntax..."
	@echo ""
	@for dir in docker/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			name=$$(basename $$dir); \
			echo -n "$$name: "; \
			if python3 -c "import yaml; yaml.safe_load(open('$$dir/docker-compose.yml'))" 2>/dev/null; then \
				echo "$(GREEN)✓ Valid YAML$(NC)"; \
			else \
				echo "$(RED)✗ Invalid YAML$(NC)"; \
			fi; \
		fi \
	done
	@echo ""
	@echo "$(GREEN)Syntax validation complete$(NC)"

test-config: ## Validate all docker compose configurations (requires Docker)
	@echo "Validating docker compose configurations..."
	@echo ""
	@for dir in docker/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			name=$$(basename $$dir); \
			echo -n "$$name: "; \
			if cd "$$dir" && docker compose config > /dev/null 2>&1; then \
				echo "$(GREEN)✓ Valid$(NC)"; \
			else \
				echo "$(RED)✗ Invalid$(NC)"; \
				cd "$$dir" && docker compose config 2>&1 | head -5; \
			fi; \
			cd - > /dev/null; \
		fi \
	done
	@echo ""
	@echo "$(GREEN)Configuration validation complete$(NC)"

test-pull: ## Pull all images without starting (verify images exist)
	@echo "Pulling all Docker images..."
	@for dir in docker/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			name=$$(basename $$dir); \
			echo "Pulling $$name..."; \
			cd "$$dir" && docker compose pull 2>&1 || true; \
			cd - > /dev/null; \
		fi \
	done
	@echo "$(GREEN)Image pull complete$(NC)"

test-dry-run: ## Start services briefly to verify they launch (then stop)
	@echo "Testing service startup (dry run)..."
	@echo "This will start services briefly and then stop them."
	@echo ""
	@for dir in docker/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			name=$$(basename $$dir); \
			echo "Testing $$name..."; \
			cd "$$dir" && \
			docker compose up -d 2>&1 && \
			sleep 5 && \
			docker compose ps && \
			docker compose down 2>&1; \
			cd - > /dev/null; \
			echo ""; \
		fi \
	done
	@echo "$(GREEN)Dry run complete$(NC)"

test: test-syntax ## Run basic tests (no Docker required)

##@ Maintenance

clean: ## Remove stopped containers and unused images
	@echo "Cleaning up Docker resources..."
	@docker container prune -f
	@docker image prune -f
	@docker volume prune -f
	@echo "$(GREEN)Cleanup complete$(NC)"

stats: ## Show Docker resource usage in real-time
	@docker stats

##@ Git

commit: ## Commit changes (interactive prompt for message, use PUSH=true to push)
	@echo "=== Git Commit ==="
	@echo ""
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "No changes to commit"; \
		exit 0; \
	fi
	@echo "Changes to be committed:"
	@git status --short
	@echo ""
	@if [ -z "$(COMMIT_MSG)" ]; then \
		echo -n "Enter commit message: "; \
		read MSG; \
		if [ -z "$$MSG" ]; then \
			echo "No message provided. Using default message."; \
			MSG="Update docker compose configurations"; \
		fi; \
		git add -A; \
		git commit -m "$$MSG" || (echo "$(RED)Commit failed$(NC)" && exit 1); \
		echo "$(GREEN)✓ Changes committed: $$MSG$(NC)"; \
	else \
		git add -A; \
		git commit -m "$(COMMIT_MSG)" || (echo "$(RED)Commit failed$(NC)" && exit 1); \
		echo "$(GREEN)✓ Changes committed: $(COMMIT_MSG)$(NC)"; \
	fi
	@if [ "$(PUSH)" = "true" ]; then \
		echo "Pushing to remote..."; \
		git push || (echo "$(RED)Push failed$(NC)" && exit 1); \
		echo "$(GREEN)✓ Changes pushed to remote$(NC)"; \
	else \
		echo "Tip: Use 'make commit PUSH=true' to push after committing"; \
	fi