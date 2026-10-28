.PHONY: help deploy deploy-all status update upgrade upgrade-service update-service backup backup-ssl restore logs restart stop start health info commit

# Configuration
DEPLOY_SCRIPT := ./deploy-auto.sh
PI_COMMANDER := ./scripts/pi-commander
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
	@echo "  $(GREEN)make upgrade$(NC)               Pull latest Docker images for all services"
	@echo "  $(GREEN)make upgrade-service SERVICE=<name>$(NC)  Upgrade specific service to latest image"
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
	@echo "  $(GREEN)make weekly-maintenance$(NC)  Run weekly Docker cleanup"
	@echo "  $(GREEN)make backup-cron-setup$(NC)       Setup weekly backups (Sunday 2 AM)"
	@echo "  $(GREEN)make reboot-cron-setup$(NC)       Setup weekly reboot (Sunday 4 AM)"
	@echo "  $(GREEN)make maintenance-cron-setup$(NC)  Setup weekly maintenance (Sunday 5 AM)"
	@echo "  $(GREEN)make cron-status$(NC)             Show all scheduled tasks"
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

upgrade: ## Pull latest Docker images and recreate all containers
	@$(PI_COMMANDER) upgrade-all

upgrade-service: ## Upgrade specific service to latest image (use: make upgrade-service SERVICE=nginx-proxy-manager)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE$(NC)"; \
		echo "Usage: make upgrade-service SERVICE=nginx-proxy-manager"; \
		exit 1; \
	fi
	@$(PI_COMMANDER) upgrade-service "$(SERVICE)"

update-service: ## Update specific service (use: make update-service SERVICE=adguard)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE$(NC)"; \
		echo "Usage: make update-service SERVICE=<service-name>"; \
		echo ""; \
		echo "Available configured services:"; \
		$(PI_COMMANDER) list-config; \
		exit 1; \
	fi
	@$(PI_COMMANDER) update-service "$(SERVICE)"

deploy-all: ## Deploy core infrastructure services
	@$(PI_COMMANDER) deploy-all

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
	@$(PI_COMMANDER) start-all

##@ Backup & Restore

backup: ## Create full backup of all data
	@sudo $(PI_COMMANDER) backup-full

backup-ssl: ## Backup SSL certificates only
	@sudo $(PI_COMMANDER) backup-ssl

restore: ## Restore from backup (use: make restore BACKUP_FILE=/path/to/backup.tar.gz)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: Please specify BACKUP_FILE$(NC)"; \
		echo "Usage: make restore BACKUP_FILE=/path/to/backup.tar.gz"; \
		ls -lh $(BACKUP_DIR)/*.tar.gz 2>/dev/null || true; \
		exit 1; \
	fi
	@sudo $(PI_COMMANDER) restore-full "$(BACKUP_FILE)"

restore-ssl: ## Restore SSL certificates (use: make restore-ssl BACKUP_FILE=/path/to/backup.tar.gz)
	@sudo $(PI_COMMANDER) restore-ssl $(BACKUP_FILE)

backup-cron-setup: ## Setup automated weekly backups (Sunday 2 AM)
	@echo "Setting up automated backups..."
	@chmod +x scripts/backup-cron.sh
	@(sudo crontab -l 2>/dev/null | grep -v "backup-cron.sh"; echo "0 2 * * 0 $(CURDIR)/scripts/backup-cron.sh") | sudo crontab -
	@echo "$(GREEN)Automated backup scheduled for Sunday 2 AM$(NC)"
	@echo "Root crontab:"
	@sudo crontab -l | grep backup-cron || true

backup-cron-remove: ## Remove automated backup cron job
	@echo "Removing automated backup cron job..."
	@sudo crontab -l 2>/dev/null | grep -v "backup-cron.sh" | sudo crontab - || true
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

maintenance-cron-setup: ## Setup weekly maintenance (Sunday 5 AM)
	@echo "Setting up weekly maintenance..."
	@(crontab -l 2>/dev/null | grep -v "weekly-maintenance"; echo "0 5 * * 0 cd $(CURDIR) && make weekly-maintenance >> /var/log/pi-commander-maintenance.log 2>&1") | crontab -
	@echo "$(GREEN)Weekly maintenance scheduled for Sunday 5 AM$(NC)"
	@echo "Current crontab:"
	@crontab -l | grep weekly-maintenance || true

maintenance-cron-remove: ## Remove weekly maintenance cron job
	@echo "Removing weekly maintenance cron job..."
	@crontab -l 2>/dev/null | grep -v "weekly-maintenance" | crontab - || true
	@echo "$(GREEN)Weekly maintenance removed$(NC)"

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
	@$(PI_COMMANDER) health

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
	@if ! python3 -c "import yaml" 2>/dev/null; then \
		echo "$(YELLOW)PyYAML is not installed; skipping YAML syntax validation$(NC)"; \
		echo "Install with: python3 -m pip install PyYAML"; \
	else \
		for dir in docker/*/; do \
			if [ -f "$$dir/docker-compose.yml" ]; then \
				name=$$(basename $$dir); \
				printf "%s: " "$$name"; \
				if python3 -c "import yaml; yaml.safe_load(open('$$dir/docker-compose.yml'))" 2>/dev/null; then \
					echo "$(GREEN)✓ Valid YAML$(NC)"; \
				else \
					echo "$(RED)✗ Invalid YAML$(NC)"; \
				fi; \
			fi; \
		done; \
	fi
	@echo ""
	@echo "$(GREEN)Syntax validation complete$(NC)"

test-config: ## Validate all docker compose configurations (requires Docker)
	@$(PI_COMMANDER) test-config

test-pull: ## Pull all images without starting (verify images exist)
	@$(PI_COMMANDER) test-pull

test-dry-run: ## Start services briefly to verify they launch (then stop)
	@$(PI_COMMANDER) test-dry-run

test: test-syntax ## Run basic tests (no Docker required)

##@ Maintenance

clean: ## Remove stopped containers and unused images
	@echo "Cleaning up Docker resources..."
	@docker container prune -f
	@docker image prune -f
	@docker volume prune -f
	@echo "$(GREEN)Cleanup complete$(NC)"

weekly-maintenance: ## Run weekly maintenance cleanup for core infrastructure host
	@echo "=== Weekly Maintenance ==="
	@$(MAKE) clean
	@echo "$(GREEN)Weekly maintenance complete$(NC)"

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
