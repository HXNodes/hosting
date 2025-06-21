#!/bin/bash

# =============================================================================
# hxnodes Server Management Panel - Streamlined Installation Script
# =============================================================================
# This script installs the hxnodes server management panel with minimal prompts
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables with sensible defaults
PANEL_DIR="/opt/hxnodes"
NODE_DIR="/opt/hxnodes-node"
REPO_URL="https://github.com/HXNodes/hosting.git"
PANEL_DOMAIN=""
SSL_ENABLED=false
DB_INSTALL=true
DB_ROOT_PASS=""
DB_NAME="hxnodes"
DB_USER="hxnodes"
DB_PASS=""
ADMIN_NAME=""
ADMIN_EMAIL=""
ADMIN_PASS=""
JWT_SECRET=""

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  hxnodes Server Management Panel - Quick Installation"
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
# QUICK CONFIGURATION
# =============================================================================

get_essential_config() {
    print_header
    
    # Get server IP/domain
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    read -p "Enter your domain or IP address [$SERVER_IP]: " PANEL_DOMAIN
    PANEL_DOMAIN=${PANEL_DOMAIN:-$SERVER_IP}
    
    # Get admin email
    read -p "Enter admin email: " ADMIN_EMAIL
    
    # Get admin password
    read -s -p "Enter admin password: " ADMIN_PASS
    echo ""
    
    # Generate secure passwords and secrets
    DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    
    print_info "Using domain: $PANEL_DOMAIN"
    print_info "Admin email: $ADMIN_EMAIL"
    print_info "Database password: $DB_PASS"
    print_info "JWT secret generated automatically"
}

# =============================================================================
# ENVIRONMENT DETECTION
# =============================================================================

detect_environment() {
    print_step "Detecting environment..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    # Check if OS is supported
    if [[ "$OS" != "Ubuntu" && "$OS" != "Debian GNU/Linux" ]]; then
        print_error "Unsupported OS: $OS. This script only supports Ubuntu and Debian."
        exit 1
    fi
    
    print_info "Detected OS: $OS $VER"
    print_success "Environment detection completed"
}

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

install_dependencies() {
    print_step "Installing dependencies..."
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install PHP 8.1+ and extensions
    apt install -y software-properties-common
    add-apt-repository ppa:ondrej/php -y
    apt update
    apt install -y php8.1 php8.1-fpm php8.1-cli php8.1-mysql php8.1-pgsql \
                   php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip \
                   php8.1-bcmath php8.1-redis php8.1-opcache
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Install other dependencies
    apt install -y nginx mariadb-server redis-server curl git wget unzip
    
    # Install Docker (skip if already installed)
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker $SUDO_USER
    fi
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Install Composer
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    
    # Start and enable services
    systemctl enable nginx mariadb redis-server
    systemctl start nginx mariadb redis-server
    
    print_success "All dependencies installed"
}

# =============================================================================
# DATABASE SETUP
# =============================================================================

setup_database() {
    print_step "Setting up database..."
    
    # Secure MariaDB installation (non-interactive)
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('$DB_PASS') WHERE User='root';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Create database and user
    mysql -u root -p"$DB_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Database setup completed"
}

# =============================================================================
# REPOSITORY CLONE
# =============================================================================

clone_repository() {
    print_step "Cloning repository..."
    
    mkdir -p $PANEL_DIR
    cd $PANEL_DIR
    
    # Try to clone (works for public repos)
    if git clone $REPO_URL . 2>/dev/null; then
        print_success "Repository cloned successfully"
        return 0
    fi
    
    # If that fails, try with local files
    print_warning "Repository clone failed, using local files"
    if [[ -d "/root/hosting" ]]; then
        cp -r /root/hosting/* .
        print_success "Local files copied"
    else
        print_error "No local files found. Please ensure the repository is accessible."
        exit 1
    fi
}

# =============================================================================
# APPLICATION SETUP
# =============================================================================

setup_backend() {
    print_step "Setting up backend..."
    
    cd $PANEL_DIR/backend
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
PORT=4000
DATABASE_URL=mysql://$DB_USER:$DB_PASS@localhost:3306/$DB_NAME
JWT_SECRET=$JWT_SECRET
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
CRYPTO_API_KEY=
BASE_URL=http://$PANEL_DOMAIN
EOF
    
    # Run database migrations if Prisma exists
    if [[ -f "prisma/schema.prisma" ]]; then
        npx prisma generate
        npx prisma migrate deploy
    fi
    
    print_success "Backend setup completed"
}

setup_frontend() {
    print_step "Setting up frontend..."
    
    cd $PANEL_DIR/frontend
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
VITE_API_BASE_URL=/api
VITE_PANEL_NAME=hxnodes
EOF
    
    # Build frontend
    npm run build
    
    print_success "Frontend setup completed"
}

# =============================================================================
# NGINX CONFIGURATION
# =============================================================================

configure_nginx() {
    print_step "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/hxnodes <<EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    
    # Frontend
    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket
    location /ws/ {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/hxnodes /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    nginx -t
    systemctl reload nginx
    
    print_success "Nginx configured"
}

# =============================================================================
# SYSTEMD SERVICES
# =============================================================================

create_services() {
    print_step "Creating systemd services..."
    
    # Backend service
    cat > /etc/systemd/system/hxnodes-backend.service <<EOF
[Unit]
Description=hxnodes Backend
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=$PANEL_DIR/backend
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Frontend service
    cat > /etc/systemd/system/hxnodes-frontend.service <<EOF
[Unit]
Description=hxnodes Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PANEL_DIR/frontend
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start services
    systemctl daemon-reload
    systemctl enable hxnodes-backend hxnodes-frontend
    systemctl start hxnodes-backend hxnodes-frontend
    
    print_success "Services created and started"
}

# =============================================================================
# SECURITY SETUP
# =============================================================================

setup_security() {
    print_step "Setting up security..."
    
    # Install and configure UFW
    apt install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw --force enable
    
    # Install fail2ban
    apt install -y fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    print_success "Security configured"
}

# =============================================================================
# FINAL SETUP
# =============================================================================

create_admin_user() {
    print_step "Creating admin user..."
    
    # This will be handled by the backend when it starts
    # The admin user will be created through the registration process
    print_info "Admin user will be created when you first access the panel"
    print_info "Email: $ADMIN_EMAIL"
    print_info "Password: (the one you entered)"
}

print_final_summary() {
    print_header
    print_success "hxnodes installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "========================"
    echo "Panel URL: http://$PANEL_DOMAIN"
    echo "Admin Email: $ADMIN_EMAIL"
    echo "Database: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Open http://$PANEL_DOMAIN in your browser"
    echo "2. Register with email: $ADMIN_EMAIL"
    echo "3. Login and start managing your servers"
    echo ""
    echo -e "${CYAN}Service Status:${NC}"
    systemctl status hxnodes-backend --no-pager -l
    systemctl status hxnodes-frontend --no-pager -l
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "View logs: journalctl -u hxnodes-backend -f"
    echo "Restart services: systemctl restart hxnodes-backend hxnodes-frontend"
    echo "Check status: systemctl status hxnodes-backend hxnodes-frontend"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    get_essential_config
    detect_environment
    install_dependencies
    setup_database
    clone_repository
    setup_backend
    setup_frontend
    configure_nginx
    create_services
    setup_security
    create_admin_user
    print_final_summary
}

# Run main function
main "$@" 