#!/bin/bash
# Pi-Commander Auto-Deploy Script
# Pulls latest changes and automatically redeploys affected services

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/pi-commander.sh
source "$SCRIPT_DIR/scripts/lib/pi-commander.sh"

REPO_DIR="${PC_REPO_DIR:-$HOME/pi-commander}"
LOCKFILE="/tmp/pi-commander-deploy.lock"

# Prevent concurrent runs
acquire_lock() {
    if [ -f "$LOCKFILE" ]; then
        pc_error "Another deployment is running. If stuck, remove: $LOCKFILE"
    fi
    touch "$LOCKFILE"
    trap "rm -f $LOCKFILE" EXIT
}

# Get changed files from git
get_changed_services() {
    local current_commit=$(git rev-parse HEAD)
    
    # Pull latest
    pc_info "Pulling latest changes from git..." >&2
    git fetch origin >&2
    
    local new_commit=$(git rev-parse origin/main)
    
    if [ "$current_commit" = "$new_commit" ]; then
        pc_log "Already up to date" >&2
        return 0
    fi
    
    # Get changed files
    local changed_files=$(git diff --name-only "$current_commit" "$new_commit")
    
    pc_info "Changes detected:" >&2
    echo "$changed_files" | sed 's/^/  - /' >&2
    
    # Pull changes
    git pull origin main >&2
    
    echo "$changed_files" | awk -F/ '/^docker\/[^/]+\// {print $2}' | sort -u | while IFS= read -r service; do
        pc_service_exists "$service" && printf '%s\n' "$service"
    done
}

# Main deployment
main_deploy() {
    acquire_lock
    
    cd "$REPO_DIR" || pc_error "Repository not found: $REPO_DIR"
    
    pc_log "Starting Pi-Commander auto-deployment"
    
    # Get changed services
    local services=$(get_changed_services)
    
    if [ -z "$services" ] || [ "$services" = "" ]; then
        pc_log "No service changes detected"
        exit 0
    fi
    
    echo ""
    pc_info "Services to deploy:"
    local clean_services=$(echo "$services" | grep -v "^$" | grep -v "^\[" || true)
    
    if [ -z "$clean_services" ]; then
        pc_log "No service changes detected"
        exit 0
    fi
    
    echo "$clean_services" | sed 's/^/  - /'
    echo ""
    
    # Deploy each service
    local deployed=0
    local failed=0
    
    while IFS= read -r service; do
        if [ -n "$service" ]; then
            if pc_deploy_service "$service"; then
                deployed=$((deployed + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done <<< "$clean_services"
    
    echo ""
    pc_log "Deployment complete"
    pc_log "Deployed: $deployed services"
    [ $failed -gt 0 ] && pc_warn "Failed: $failed services"
    
    # Show status
    echo ""
    pc_info "Container status:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | head -20
}

# Force deploy all services
deploy_all() {
    acquire_lock
    
    cd "$REPO_DIR" || pc_error "Repository not found: $REPO_DIR"
    
    pc_log "Deploying all core infrastructure services"
    
    # Pull latest
    git pull origin main
    pc_deploy_all
}

# Quick status
show_status() {
    cd "$REPO_DIR" || pc_error "Repository not found: $REPO_DIR"
    
    pc_info "Pi-Commander Status"
    echo ""
    
    # Git status
    pc_info "Repository:"
    local current=$(git rev-parse --short HEAD)
    local branch=$(git branch --show-current)
    echo "  Branch: $branch"
    echo "  Commit: $current"
    
    # Check for updates
    git fetch origin --quiet
    local behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "0")
    if [ "$behind" -gt 0 ]; then
        pc_warn "  Behind origin by $behind commits"
    else
        pc_log "  Up to date"
    fi
    
    echo ""
    
    # Container status
    pc_info "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
}

# Show help
show_help() {
    cat << 'EOF'
🚀 Pi-Commander Auto-Deploy

USAGE:
    ./deploy-auto.sh [command]

COMMANDS:
    deploy (default)   Pull git changes and deploy affected services
    deploy-all         Force deploy all services
    status             Show repository and container status
    help               Show this help

WORKFLOW:
    1. Pull latest changes from git
    2. Detect which services changed
    3. Automatically redeploy only affected services

EXAMPLES:
    ./deploy-auto.sh              # Auto-deploy changes
    ./deploy-auto.sh deploy-all   # Deploy everything
    ./deploy-auto.sh status       # Check status

SETUP (First Time):
    # Clone repo
    cd ~
    git clone https://github.com/yourusername/pi-commander.git

    # Configure
    cd pi-commander
    for dir in docker/*/; do
        [ -f "\$dir.env.example" ] && cp "\$dir.env.example" "\$dir.env"
    done
    # Edit .env files with your credentials

    # Deploy
    ./deploy-auto.sh deploy-all

CRON JOB (Optional):
    # Auto-update daily at 3 AM
    0 3 * * * /home/yourusername/pi-commander/deploy-auto.sh >> /var/log/pi-commander-deploy.log 2>&1

EOF
}

# Main
case "${1:-deploy}" in
    deploy)
        main_deploy
        ;;
    deploy-all)
        deploy_all
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        pc_error "Unknown command: $1. Use 'help' for usage."
        ;;
esac
