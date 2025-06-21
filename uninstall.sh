#!/bin/bash

# =============================================================================
# hxnodes Uninstallation Script
# =============================================================================
# This script completely removes hxnodes from the system
# WARNING: This will delete all data and configurations
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories to remove
PANEL_DIR="/opt/hxnodes"
NODE_DIR="/opt/hxnodes-node"
WEB_DIR="/var/www/hxnodes"
BACKUP_DIR="/var/backups/hxnodes"
LOG_DIR="/var/log/hxnodes"
UPLOAD_DIR="/var/hxnodes/uploads"

# Services to stop and remove
SERVICES=("hxnodes-backend" "hxnodes-frontend" "hxnodes-node-agent")

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  hxnodes Uninstallation Script"
    echo "============================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# =============================================================================
# CONFIRMATION
# =============================================================================

confirm_uninstall() {
    print_header
    echo -e "${RED}WARNING: This will completely remove hxnodes from your system!${NC}"
    echo ""
    echo "The following will be deleted:"
    echo "  • All hxnodes files and directories"
    echo "  • Database and all data"
    echo "  • Systemd services"
    echo "  • Nginx configurations"
    echo "  • User accounts and configurations"
    echo "  • Backups and logs"
    echo ""
    echo -e "${YELLOW}This action cannot be undone!${NC}"
    echo ""
    
    read -p "Are you absolutely sure you want to continue? (type 'YES' to confirm): " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    
    echo ""
    read -p "Do you want to backup your data before uninstalling? (y/n): " backup_choice
    
    if [[ $backup_choice =~ ^[Yy]$ ]]; then
        create_backup
    fi
}

# =============================================================================
# BACKUP FUNCTION
# =============================================================================

create_backup() {
    print_step "Creating backup before uninstallation..."
    
    local backup_name="hxnodes_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_file="/tmp/${backup_name}.tar.gz"
    
    # Create backup directory
    mkdir -p /tmp/hxnodes_backup
    
    # Backup panel files
    if [[ -d "$PANEL_DIR" ]]; then
        cp -r "$PANEL_DIR" /tmp/hxnodes_backup/
        print_info "Panel files backed up"
    fi
    
    # Backup node files
    if [[ -d "$NODE_DIR" ]]; then
        cp -r "$NODE_DIR" /tmp/hxnodes_backup/
        print_info "Node files backed up"
    fi
    
    # Backup web files
    if [[ -d "$WEB_DIR" ]]; then
        cp -r "$WEB_DIR" /tmp/hxnodes_backup/
        print_info "Web files backed up"
    fi
    
    # Backup uploads
    if [[ -d "$UPLOAD_DIR" ]]; then
        cp -r "$UPLOAD_DIR" /tmp/hxnodes_backup/
        print_info "Uploads backed up"
    fi
    
    # Backup logs
    if [[ -d "$LOG_DIR" ]]; then
        cp -r "$LOG_DIR" /tmp/hxnodes_backup/
        print_info "Logs backed up"
    fi
    
    # Backup database
    if command -v pg_dump &> /dev/null; then
        pg_dump hxnodes > /tmp/hxnodes_backup/database.sql 2>/dev/null || true
        print_info "Database backed up"
    fi
    
    # Create archive
    tar -czf "$backup_file" -C /tmp hxnodes_backup
    rm -rf /tmp/hxnodes_backup
    
    print_success "Backup created: $backup_file"
    echo "You can restore from this backup if needed."
}

# =============================================================================
# SERVICE REMOVAL
# =============================================================================

stop_and_remove_services() {
    print_step "Stopping and removing services..."
    
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            print_info "Stopping $service..."
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            
            # Remove service file
            if [[ -f "/etc/systemd/system/$service.service" ]]; then
                rm -f "/etc/systemd/system/$service.service"
                print_info "Removed service file: $service.service"
            fi
        fi
    done
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "Services stopped and removed"
}

# =============================================================================
# DIRECTORY CLEANUP
# =============================================================================

remove_directories() {
    print_step "Removing hxnodes directories..."
    
    local directories=(
        "$PANEL_DIR"
        "$NODE_DIR"
        "$WEB_DIR"
        "$BACKUP_DIR"
        "$LOG_DIR"
        "$UPLOAD_DIR"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_info "Removed directory: $dir"
        fi
    done
    
    print_success "Directories removed"
}

# =============================================================================
# DATABASE CLEANUP
# =============================================================================

remove_database() {
    print_step "Removing database..."
    
    # Try PostgreSQL
    if command -v psql &> /dev/null; then
        print_info "Removing PostgreSQL database..."
        sudo -u postgres dropdb hxnodes 2>/dev/null || true
        sudo -u postgres dropuser hxnodes 2>/dev/null || true
    fi
    
    # Try MySQL/MariaDB
    if command -v mysql &> /dev/null; then
        print_info "Removing MySQL/MariaDB database..."
        mysql -u root -e "DROP DATABASE IF EXISTS hxnodes;" 2>/dev/null || true
        mysql -u root -e "DROP USER IF EXISTS 'hxnodes'@'localhost';" 2>/dev/null || true
    fi
    
    print_success "Database removed"
}

# =============================================================================
# NGINX CLEANUP
# =============================================================================

remove_nginx_config() {
    print_step "Removing Nginx configuration..."
    
    # Remove site configuration
    if [[ -f "/etc/nginx/sites-available/hxnodes" ]]; then
        rm -f "/etc/nginx/sites-available/hxnodes"
        print_info "Removed Nginx site config"
    fi
    
    # Remove from sites-enabled
    if [[ -L "/etc/nginx/sites-enabled/hxnodes" ]]; then
        rm -f "/etc/nginx/sites-enabled/hxnodes"
        print_info "Removed Nginx site link"
    fi
    
    # Test and reload Nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_info "Nginx configuration reloaded"
    fi
    
    print_success "Nginx configuration removed"
}

# =============================================================================
# USER CLEANUP
# =============================================================================

remove_users() {
    print_step "Removing hxnodes users..."
    
    # Remove hxnodes user if it exists
    if id "hxnodes" &>/dev/null; then
        userdel -r hxnodes 2>/dev/null || true
        print_info "Removed hxnodes user"
    fi
    
    print_success "Users removed"
}

# =============================================================================
# CRON CLEANUP
# =============================================================================

remove_cron_jobs() {
    print_step "Removing cron jobs..."
    
    # Remove hxnodes cron jobs
    crontab -l 2>/dev/null | grep -v "hxnodes" | crontab - 2>/dev/null || true
    
    print_success "Cron jobs removed"
}

# =============================================================================
# DOCKER CLEANUP
# =============================================================================

remove_docker_containers() {
    print_step "Removing Docker containers..."
    
    if command -v docker &> /dev/null; then
        # Stop and remove hxnodes containers
        docker ps -a --filter "name=hxnodes" --format "{{.ID}}" | xargs -r docker stop 2>/dev/null || true
        docker ps -a --filter "name=hxnodes" --format "{{.ID}}" | xargs -r docker rm 2>/dev/null || true
        
        # Remove hxnodes images
        docker images --filter "reference=*hxnodes*" --format "{{.ID}}" | xargs -r docker rmi 2>/dev/null || true
        
        # Remove hxnodes volumes
        docker volume ls --filter "name=hxnodes" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
        
        print_info "Docker containers and images removed"
    fi
    
    print_success "Docker cleanup completed"
}

# =============================================================================
# PACKAGE CLEANUP (OPTIONAL)
# =============================================================================

remove_packages() {
    print_step "Removing hxnodes packages..."
    
    read -p "Do you want to remove Node.js, PHP, and other dependencies? (y/n): " remove_deps
    
    if [[ $remove_deps =~ ^[Yy]$ ]]; then
        # Remove Node.js
        if command -v node &> /dev/null; then
            apt remove -y nodejs npm
            print_info "Node.js removed"
        fi
        
        # Remove PHP
        if command -v php &> /dev/null; then
            apt remove -y php8.1* php8.2* php8.3*
            print_info "PHP removed"
        fi
        
        # Remove Docker
        if command -v docker &> /dev/null; then
            apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            print_info "Docker removed"
        fi
        
        # Remove Redis
        if command -v redis-server &> /dev/null; then
            apt remove -y redis-server
            print_info "Redis removed"
        fi
        
        # Remove Composer
        if command -v composer &> /dev/null; then
            rm -f /usr/local/bin/composer
            print_info "Composer removed"
        fi
        
        # Clean up
        apt autoremove -y
        apt autoclean
    fi
    
    print_success "Package cleanup completed"
}

# =============================================================================
# FINAL CLEANUP
# =============================================================================

final_cleanup() {
    print_step "Performing final cleanup..."
    
    # Remove temporary files
    rm -rf /tmp/hxnodes_*
    
    # Remove any remaining hxnodes files
    find /tmp -name "*hxnodes*" -delete 2>/dev/null || true
    find /var/tmp -name "*hxnodes*" -delete 2>/dev/null || true
    
    # Clear any cached data
    systemctl daemon-reload
    
    print_success "Final cleanup completed"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    confirm_uninstall
    
    print_step "Starting hxnodes uninstallation..."
    
    stop_and_remove_services
    remove_directories
    remove_database
    remove_nginx_config
    remove_users
    remove_cron_jobs
    remove_docker_containers
    remove_packages
    final_cleanup
    
    print_success "hxnodes has been completely removed from your system!"
    echo ""
    echo "Summary of what was removed:"
    echo "  • All hxnodes files and directories"
    echo "  • Systemd services"
    echo "  • Database and data"
    echo "  • Nginx configurations"
    echo "  • Docker containers and images"
    echo "  • User accounts"
    echo "  • Cron jobs"
    echo ""
    echo "If you created a backup, you can restore it if needed."
    echo "The system is now clean of hxnodes components."
}

# Run main function
main "$@" 