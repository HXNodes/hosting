#!/bin/bash

# =============================================================================
# hxnodes Server Management Panel - Linux Installation Script
# =============================================================================
# This script installs the hxnodes server management panel on Ubuntu/Debian
# Supports both web panel and node agent installations
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
PANEL_DIR="/opt/hxnodes"
NODE_DIR="/opt/hxnodes-node"
REPO_URL="https://github.com/yourusername/hxnodes.git"
PANEL_DOMAIN=""
SSL_ENABLED=false
SSL_EMAIL=""
DB_INSTALL=false
DB_ROOT_PASS=""
DB_NAME=""
DB_USER=""
DB_PASS=""
ADMIN_NAME=""
ADMIN_EMAIL=""
ADMIN_PASS=""
JWT_SECRET=""

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  hxnodes Server Management Panel - Linux Installation Script"
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
    
    # Check if panel is already installed
    if [[ -d "$PANEL_DIR" ]]; then
        print_warning "Panel directory already exists at $PANEL_DIR"
        read -p "Do you want to continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Environment detection completed"
}

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

update_system() {
    print_step "Updating system packages..."
    apt update
    apt upgrade -y
    print_success "System updated"
}

install_php() {
    print_step "Installing PHP 8.1+ and extensions..."
    
    # Add PHP repository for Ubuntu
    if [[ "$OS" == "Ubuntu" ]]; then
        apt install -y software-properties-common
        add-apt-repository ppa:ondrej/php -y
        apt update
    fi
    
    # Install PHP and extensions (json is now included in core PHP)
    apt install -y php8.1 php8.1-fpm php8.1-cli php8.1-mysql php8.1-pgsql \
                   php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip \
                   php8.1-bcmath php8.1-redis php8.1-opcache
    
    print_success "PHP installed"
}

install_nginx() {
    print_step "Installing Nginx..."
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    print_success "Nginx installed and started"
}

install_nodejs() {
    print_step "Installing Node.js and npm..."
    
    # Install Node.js 18.x
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    print_success "Node.js $(node --version) and npm $(npm --version) installed"
}

install_composer() {
    print_step "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    print_success "Composer installed"
}

install_redis() {
    print_step "Installing Redis..."
    apt install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server
    print_success "Redis installed and started"
}

install_docker() {
    print_step "Installing Docker and Docker Compose..."
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker and Docker Compose installed"
}

install_certbot() {
    print_step "Installing Certbot..."
    apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
}

install_security_tools() {
    print_step "Installing security tools..."
    
    # Install fail2ban
    apt install -y fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    # Install and configure UFW
    apt install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw --force enable
    
    print_success "Security tools installed and configured"
}

install_dependencies() {
    print_step "Installing all dependencies..."
    
    update_system
    install_php
    install_nginx
    install_nodejs
    install_composer
    install_redis
    install_docker
    install_certbot
    
    # Install additional tools
    apt install -y unzip curl git wget
    
    print_success "All dependencies installed"
}

# =============================================================================
# DATABASE SETUP
# =============================================================================

install_mariadb() {
    print_step "Installing MariaDB..."
    apt install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
    
    # Secure MariaDB installation
    mysql_secure_installation
    
    print_success "MariaDB installed and secured"
}

create_database() {
    print_step "Creating database and user..."
    
    # Create database and user
    mysql -u root -p"$DB_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Database and user created"
}

# =============================================================================
# WEB PANEL INSTALLATION
# =============================================================================

clone_repository() {
    print_step "Cloning hxnodes repository..."
    
    mkdir -p $PANEL_DIR
    cd $PANEL_DIR
    
    # Check if repository is public or private
    print_info "Checking repository access..."
    
    # Try to clone without authentication first (for public repos)
    if git clone $REPO_URL . 2>/dev/null; then
        print_success "Repository cloned successfully (public repository)"
        return 0
    fi
    
    # If that fails, ask for authentication method
    print_warning "Repository appears to be private or requires authentication"
    echo ""
    echo "Authentication options:"
    echo "1) Use Personal Access Token (recommended)"
    echo "2) Use SSH key"
    echo "3) Skip and use local files"
    echo ""
    
    read -p "Choose authentication method (1-3): " auth_choice
    
    case $auth_choice in
        1)
            # Personal Access Token
            echo ""
            echo "To create a Personal Access Token:"
            echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
            echo "2. Generate new token with 'repo' scope"
            echo "3. Copy the token"
            echo ""
            read -p "Enter your GitHub username: " github_username
            read -s -p "Enter your Personal Access Token: " github_token
            echo ""
            
            # Clone with token
            if git clone https://${github_username}:${github_token}@github.com/${github_username}/hxnodes.git .; then
                print_success "Repository cloned successfully with token"
            else
                print_error "Failed to clone repository with token"
                return 1
            fi
            ;;
        2)
            # SSH key
            print_info "Using SSH authentication"
            if git clone git@github.com:$(echo $REPO_URL | sed 's|https://github.com/||') .; then
                print_success "Repository cloned successfully with SSH"
            else
                print_error "Failed to clone repository with SSH"
                print_info "Make sure your SSH key is added to GitHub"
                return 1
            fi
            ;;
        3)
            # Skip and use local files
            print_info "Skipping repository clone, using local files"
            if [[ -d "/root/hxnodes" ]]; then
                cp -r /root/hxnodes/* .
                print_success "Local files copied"
            else
                print_error "No local files found in /root/hxnodes"
                return 1
            fi
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
}

setup_backend() {
    print_step "Setting up backend..."
    
    cd $PANEL_DIR/backend
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
PORT=4000
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
JWT_SECRET=$JWT_SECRET
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
CRYPTO_API_KEY=
BASE_URL=https://$PANEL_DOMAIN
EOF
    
    # Run database migrations
    npx prisma migrate deploy
    
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
EOF
    
    # Build frontend
    npm run build
    
    print_success "Frontend setup completed"
}

setup_node_agent() {
    print_step "Setting up node agent..."
    
    cd $PANEL_DIR/node-agent
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
AGENT_PORT=5001
NODE_NAME=main-node
EOF
    
    print_success "Node agent setup completed"
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

setup_ssl() {
    if [[ "$SSL_ENABLED" == true ]]; then
        print_step "Setting up SSL with Let's Encrypt..."
        
        certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos -m $SSL_EMAIL
        
        # Set up auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        print_success "SSL configured with auto-renewal"
    fi
}

# =============================================================================
# SYSTEMD SERVICES
# =============================================================================

create_systemd_services() {
    print_step "Creating systemd services..."
    
    # Backend service
    cat > /etc/systemd/system/hxnodes-backend.service <<EOF
[Unit]
Description=hxnodes Backend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PANEL_DIR/backend
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

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
User=www-data
WorkingDirectory=$PANEL_DIR/frontend
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Node agent service
    cat > /etc/systemd/system/hxnodes-node.service <<EOF
[Unit]
Description=hxnodes Node Agent
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PANEL_DIR/node-agent
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start services
    systemctl daemon-reload
    systemctl enable hxnodes-backend hxnodes-frontend hxnodes-node
    systemctl start hxnodes-backend hxnodes-frontend hxnodes-node
    
    print_success "Systemd services created and started"
}

# =============================================================================
# PERMISSIONS AND SECURITY
# =============================================================================

set_permissions() {
    print_step "Setting correct permissions..."
    
    chown -R www-data:www-data $PANEL_DIR
    chmod -R 755 $PANEL_DIR
    
    print_success "Permissions set"
}

# =============================================================================
# NODE AGENT INSTALLATION
# =============================================================================

install_node_agent() {
    print_step "Installing Node Agent..."
    
    mkdir -p $NODE_DIR
    cd $NODE_DIR
    
    # Clone repository
    git clone $REPO_URL .
    
    # Setup node agent
    cd node-agent
    npm install
    
    # Create .env file
    cat > .env <<EOF
AGENT_PORT=5001
NODE_NAME=main-node
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/hxnodes-node-agent.service <<EOF
[Unit]
Description=hxnodes Node Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$NODE_DIR/node-agent
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable hxnodes-node-agent
    systemctl start hxnodes-node-agent
    
    print_success "Node Agent installed and started"
}

# =============================================================================
# USER INTERFACE
# =============================================================================

get_installation_type() {
    print_header
    
    echo "What do you want to install?"
    echo "1) Web Panel (frontend/backend)"
    echo "2) Server Daemon / Node Agent"
    echo ""
    read -p "Enter your choice (1 or 2): " INSTALL_TYPE
    
    case $INSTALL_TYPE in
        1)
            install_web_panel
            ;;
        2)
            install_node_agent
            print_final_summary_node
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

get_web_panel_config() {
    print_step "Web Panel Configuration"
    
    read -p "Enter your domain (e.g., panel.yourdomain.com): " PANEL_DOMAIN
    
    read -p "Do you want to install Let's Encrypt SSL for this domain? (y/n): " SSL_CHOICE
    if [[ $SSL_CHOICE =~ ^[Yy]$ ]]; then
        SSL_ENABLED=true
        read -p "Enter your email address for SSL: " SSL_EMAIL
    fi
    
    read -p "Do you want to install MariaDB now? (y/n): " DB_CHOICE
    if [[ $DB_CHOICE =~ ^[Yy]$ ]]; then
        DB_INSTALL=true
        read -sp "Enter MariaDB root password: " DB_ROOT_PASS
        echo
        read -p "Enter database name [hxnodes]: " DB_NAME
        DB_NAME=${DB_NAME:-hxnodes}
        read -p "Enter database username [hxadmin]: " DB_USER
        DB_USER=${DB_USER:-hxadmin}
        read -sp "Enter database password: " DB_PASS
        echo
    fi
    
    echo ""
    echo "Admin User Setup:"
    read -p "Enter admin name: " ADMIN_NAME
    read -p "Enter admin email: " ADMIN_EMAIL
    read -sp "Enter admin password: " ADMIN_PASS
    echo
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -hex 32)
}

install_web_panel() {
    get_web_panel_config
    
    print_step "Starting Web Panel installation..."
    
    detect_environment
    install_dependencies
    
    if [[ "$DB_INSTALL" == true ]]; then
        install_mariadb
        create_database
    fi
    
    clone_repository
    setup_backend
    setup_frontend
    setup_node_agent
    configure_nginx
    
    if [[ "$SSL_ENABLED" == true ]]; then
        setup_ssl
    fi
    
    create_systemd_services
    set_permissions
    
    # Ask about security tools
    read -p "Do you want to install fail2ban and configure UFW firewall? (y/n): " SECURITY_CHOICE
    if [[ $SECURITY_CHOICE =~ ^[Yy]$ ]]; then
        install_security_tools
    fi
    
    print_final_summary_web
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================

print_final_summary_web() {
    print_header
    print_success "Web Panel installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "========================"
    echo "Panel URL: https://$PANEL_DOMAIN"
    echo "Admin Email: $ADMIN_EMAIL"
    echo "Admin Password: [as entered]"
    if [[ "$DB_INSTALL" == true ]]; then
        echo "Database: $DB_NAME"
        echo "Database User: $DB_USER"
        echo "Database Password: [as entered]"
    fi
    echo "SSL Status: $([[ "$SSL_ENABLED" == true ]] && echo "Enabled" || echo "Disabled")"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Visit https://$PANEL_DOMAIN"
    echo "2. Login with your admin credentials"
    echo "3. Configure your first server node"
    echo "4. Set up payment gateways if needed"
    echo ""
    echo -e "${CYAN}Services Status:${NC}"
    systemctl status hxnodes-backend --no-pager -l
    systemctl status hxnodes-frontend --no-pager -l
    systemctl status hxnodes-node --no-pager -l
}

print_final_summary_node() {
    print_header
    print_success "Node Agent installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "========================"
    echo "Node Agent Port: 5001"
    echo "Node Name: main-node"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Configure the node in your web panel"
    echo "2. Add the node's IP and port to your panel"
    echo "3. Test the connection"
    echo ""
    echo -e "${CYAN}Service Status:${NC}"
    systemctl status hxnodes-node-agent --no-pager -l
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    get_installation_type
}

# Run main function
main "$@" 