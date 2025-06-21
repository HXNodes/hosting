#!/bin/bash

# =============================================================================
# hxnodes Installation Script (Pterodactyl Style)
# =============================================================================
# This script installs hxnodes panel, daemon, or uninstalls them
# =============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directories
PANEL_DIR="/var/www/hxnodes"
DAEMON_DIR="/opt/hxnodes-daemon"
REPO_URL="https://github.com/HXNodes/hosting.git"

# Database
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="hxnodes"
DB_USER="hxnodes"
DB_PASS=""

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  hxnodes Installation Script"
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
# PANEL INSTALLATION FUNCTIONS
# =============================================================================

install_panel() {
    print_header
    echo "Installing hxnodes Panel..."
    echo ""
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Get essential configuration
    get_panel_config
    
    # Install dependencies
    install_dependencies
    
    # Setup database
    setup_database
    
    # Install panel
    install_panel_files
    
    # Setup backend
    setup_backend
    
    # Setup frontend
    setup_frontend
    
    # Configure nginx
    configure_nginx
    
    # Create services
    create_panel_services
    
    # Setup security
    setup_security
    
    print_panel_summary
}

get_panel_config() {
    print_step "Panel Configuration"
    
    # Get domain/IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    read -p "Enter your domain or IP address [$SERVER_IP]: " PANEL_DOMAIN
    PANEL_DOMAIN=${PANEL_DOMAIN:-$SERVER_IP}
    
    # Get admin email
    read -p "Enter admin email: " ADMIN_EMAIL
    
    # Get admin password
    read -s -p "Enter admin password: " ADMIN_PASS
    echo ""
    
    # Get database password
    read -s -p "Enter database password: " DB_PASS
    echo ""
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    
    print_info "Using domain: $PANEL_DOMAIN"
    print_info "Admin email: $ADMIN_EMAIL"
    print_info "Database password: $DB_PASS"
}

install_dependencies() {
    print_step "Installing dependencies..."
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install PHP 8.1+
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
    
    # BULLETPROOF MariaDB Setup
    print_info "Setting up MariaDB (bulletproof method)..."
    
    # Stop all MariaDB processes
    systemctl stop mariadb 2>/dev/null || true
    pkill -f mariadbd 2>/dev/null || true
    pkill -f mysqld 2>/dev/null || true
    sleep 3
    
    # Backup existing data if it exists
    if [[ -d "/var/lib/mysql" ]] && [[ -f "/var/lib/mysql/ibdata1" ]]; then
        print_info "Backing up existing MariaDB data..."
        mv /var/lib/mysql /var/lib/mysql.backup.$(date +%s)
    fi
    
    # Create fresh data directory
    rm -rf /var/lib/mysql
    mkdir -p /var/lib/mysql
    chown mysql:mysql /var/lib/mysql
    chmod 755 /var/lib/mysql
    
    # Initialize MariaDB using the most reliable method
    print_info "Initializing MariaDB data directory..."
    
    # Method 1: Try mariadb-install-db (modern)
    if command -v mariadb-install-db &> /dev/null; then
        print_info "Using mariadb-install-db..."
        mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    # Method 2: Try mysqld --initialize (modern)
    elif command -v mysqld &> /dev/null; then
        print_info "Using mysqld --initialize..."
        mysqld --initialize-insecure --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    # Method 3: Try mysql_install_db (legacy)
    elif command -v mysql_install_db &> /dev/null; then
        print_info "Using mysql_install_db..."
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    else
        print_error "No MariaDB initialization tool found!"
        exit 1
    fi
    
    # Set proper permissions
    chown -R mysql:mysql /var/lib/mysql
    chmod -R 755 /var/lib/mysql
    
    # Enable services (but don't start MariaDB yet)
    systemctl enable nginx redis-server
    
    # Start MariaDB manually (not via systemctl)
    print_info "Starting MariaDB manually..."
    
    # Start MariaDB daemon directly
    mysqld --user=mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysqld.sock &
    MYSQLD_PID=$!
    
    # Wait for MariaDB to be ready
    sleep 10
    
    # Check if MariaDB is running
    if kill -0 $MYSQLD_PID 2>/dev/null; then
        print_success "MariaDB started successfully (PID: $MYSQLD_PID)!"
        
        # Create systemd override to use our running instance
        mkdir -p /etc/systemd/system/mariadb.service.d
        cat > /etc/systemd/system/mariadb.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/bin/true
EOF
        
        # Reload systemd and mark MariaDB as active
        systemctl daemon-reload
        systemctl enable mariadb
        
    else
        print_error "MariaDB failed to start manually"
        print_error "MariaDB error logs:"
        tail -20 /var/log/mysql/error.log 2>/dev/null || echo "No error log found"
        exit 1
    fi
    
    # Verify MariaDB is working
    print_info "Verifying MariaDB connection..."
    if mysql -u root -e "SELECT 1;" 2>/dev/null; then
        print_success "MariaDB is working correctly!"
    else
        print_error "MariaDB is not responding properly"
        exit 1
    fi
    
    # Start other services
    systemctl start nginx redis-server
    
    print_success "All dependencies installed and services started successfully!"
}

setup_database() {
    print_step "Setting up database..."
    
    print_info "Configuring MariaDB for hxnodes..."
    
    # Check if MariaDB is running (either via systemctl or manually)
    if ! systemctl is-active --quiet mariadb && ! pgrep -f "mysqld.*--user=mysql" > /dev/null; then
        print_error "MariaDB is not running. Starting it manually..."
        
        # Start MariaDB manually
        mysqld --user=mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysqld.sock &
        sleep 5
        
        if ! pgrep -f "mysqld.*--user=mysql" > /dev/null; then
            print_error "Failed to start MariaDB"
            exit 1
        fi
    fi
    
    # Set root password (MariaDB should have no password initially)
    print_info "Setting MariaDB root password..."
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS';
FLUSH PRIVILEGES;
EOF
    
    # Verify the password works
    if ! mysql -u root -p"$DB_PASS" -e "SELECT 1;" 2>/dev/null; then
        print_error "Failed to set MariaDB root password"
        exit 1
    fi
    
    print_info "MariaDB root password set successfully"
    
    # Secure the installation
    mysql -u root -p"$DB_PASS" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
    
    # Create database and user
    mysql -u root -p"$DB_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Database setup completed"
}

install_panel_files() {
    print_step "Installing panel files..."
    
    mkdir -p $PANEL_DIR
    cd $PANEL_DIR
    
    # Try to clone (works for public repos)
    if git clone $REPO_URL . 2>/dev/null; then
        print_success "Repository cloned successfully"
    else
        # If that fails, try with local files
        print_warning "Repository clone failed, checking for local files..."
        
        # Get the directory where the script is running from
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        CURRENT_DIR="$(pwd)"
        
        print_info "Script directory: $SCRIPT_DIR"
        print_info "Current directory: $CURRENT_DIR"
        
        # Check multiple possible locations for the project files
        POSSIBLE_LOCATIONS=(
            "$SCRIPT_DIR"
            "/root/hosting"
            "/home/$SUDO_USER/hosting"
            "/tmp/hosting"
            "$CURRENT_DIR"
        )
        
        FOUND_LOCATION=""
        
        for location in "${POSSIBLE_LOCATIONS[@]}"; do
            print_info "Checking location: $location"
            
            if [[ -d "$location" ]] && [[ -f "$location/backend/package.json" ]] && [[ -f "$location/frontend/package.json" ]]; then
                FOUND_LOCATION="$location"
                print_success "Found project files at: $location"
                break
            fi
        done
        
        if [[ -n "$FOUND_LOCATION" ]]; then
            print_info "Using source location: $FOUND_LOCATION"
            
            # Check if we're already in the correct location
            if [[ "$FOUND_LOCATION" == "$PANEL_DIR" ]] || [[ "$FOUND_LOCATION" == "$(pwd)" ]]; then
                print_info "Files are already in the correct location ($PANEL_DIR)"
                print_success "No copying needed - files are already in place"
            else
                # Copy only specific project directories and files
                if [[ -d "$FOUND_LOCATION/backend" ]]; then
                    cp -r "$FOUND_LOCATION/backend" ./
                    print_info "Backend directory copied"
                fi
                
                if [[ -d "$FOUND_LOCATION/frontend" ]]; then
                    cp -r "$FOUND_LOCATION/frontend" ./
                    print_info "Frontend directory copied"
                fi
                
                if [[ -d "$FOUND_LOCATION/node-agent" ]]; then
                    cp -r "$FOUND_LOCATION/node-agent" ./
                    print_info "Node agent directory copied"
                fi
                
                if [[ -d "$FOUND_LOCATION/docs" ]]; then
                    cp -r "$FOUND_LOCATION/docs" ./
                    print_info "Docs directory copied"
                fi
                
                if [[ -d "$FOUND_LOCATION/scripts" ]]; then
                    cp -r "$FOUND_LOCATION/scripts" ./
                    print_info "Scripts directory copied"
                fi
                
                # Copy individual files
                for file in README.md install.sh setup.sh uninstall.sh install-node.sh; do
                    if [[ -f "$FOUND_LOCATION/$file" ]]; then
                        cp "$FOUND_LOCATION/$file" ./
                        print_info "File $file copied"
                    fi
                done
                
                print_success "Project files copied from $FOUND_LOCATION"
            fi
            
        else
            print_error "No local files found in any expected location."
            print_info "Checked locations:"
            for location in "${POSSIBLE_LOCATIONS[@]}"; do
                if [[ -d "$location" ]]; then
                    print_info "  ✓ $location (exists)"
                    if [[ -f "$location/backend/package.json" ]]; then
                        print_info "    ✓ Has backend/package.json"
                    else
                        print_info "    ✗ Missing backend/package.json"
                    fi
                    if [[ -f "$location/frontend/package.json" ]]; then
                        print_info "    ✓ Has frontend/package.json"
                    else
                        print_info "    ✗ Missing frontend/package.json"
                    fi
                else
                    print_info "  ✗ $location (does not exist)"
                fi
            done
            
            print_info "You can:"
            print_info "1. Make the repository public"
            print_info "2. Clone it manually to /root/hosting"
            print_info "3. Place the files in the current directory"
            exit 1
        fi
    fi
    
    # Set permissions
    chown -R www-data:www-data $PANEL_DIR
    chmod -R 755 $PANEL_DIR
}

setup_backend() {
    print_step "Setting up backend..."
    
    cd $PANEL_DIR/backend
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
PORT=4000
DATABASE_URL=mysql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME
JWT_SECRET=$JWT_SECRET
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
CRYPTO_API_KEY=
BASE_URL=http://$PANEL_DOMAIN
EOF
    
    # Update Prisma schema to use MySQL if it exists
    if [[ -f "prisma/schema.prisma" ]]; then
        print_info "Updating Prisma schema to use MySQL..."
        
        # Update the provider from postgresql to mysql
        sed -i 's/provider = "postgresql"/provider = "mysql"/g' prisma/schema.prisma
        
        print_info "Setting up Prisma database..."
        
        # Generate Prisma client
        npx prisma generate
        
        # Create and run initial migration
        npx prisma migrate dev --name init --create-only
        npx prisma migrate deploy
        
        print_success "Prisma database setup completed"
    fi
    
    print_success "Backend setup completed"
}

setup_frontend() {
    print_step "Setting up frontend..."
    
    cd $PANEL_DIR/frontend
    
    # Install dependencies
    npm install
    
    # Create missing frontend files if they don't exist
    if [[ ! -f "index.html" ]]; then
        print_info "Creating index.html..."
        cat > index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>hxnodes - Game Server Management</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
    fi
    
    if [[ ! -f "vite.config.ts" ]]; then
        print_info "Creating vite.config.ts..."
        cat > vite.config.ts <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true,
      },
      '/ws': {
        target: 'ws://localhost:4000',
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
})
EOF
    fi
    
    if [[ ! -f "tsconfig.json" ]]; then
        print_info "Creating tsconfig.json..."
        cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
    fi
    
    if [[ ! -f "tsconfig.node.json" ]]; then
        print_info "Creating tsconfig.node.json..."
        cat > tsconfig.node.json <<'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF
    fi
    
    # Create src directory and files
    mkdir -p src
    
    if [[ ! -f "src/main.tsx" ]]; then
        print_info "Creating src/main.tsx..."
        cat > src/main.tsx <<'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF
    fi
    
    if [[ ! -f "src/index.css" ]]; then
        print_info "Creating src/index.css..."
        cat > src/index.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
  color-scheme: light dark;
  color: rgba(255, 255, 255, 0.87);
  background-color: #242424;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-text-size-adjust: 100%;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
}

#root {
  width: 100%;
  min-height: 100vh;
}
EOF
    fi
    
    if [[ ! -f "src/App.tsx" ]]; then
        print_info "Creating src/App.tsx..."
        cat > src/App.tsx <<'EOF'
import React from 'react'

function App() {
  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-center mb-8">
          hxnodes - Game Server Management
        </h1>
        <div className="bg-gray-800 rounded-lg p-6 max-w-md mx-auto">
          <p className="text-center text-gray-300">
            Welcome to hxnodes! Your game server management panel is being set up.
          </p>
          <div className="mt-4 text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-2 text-sm text-gray-400">Loading...</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
EOF
    fi
    
    # Create .env file
    cat > .env <<EOF
VITE_API_BASE_URL=/api
VITE_PANEL_NAME=hxnodes
EOF
    
    # Install additional dependencies if needed
    npm install vite @vitejs/plugin-react @types/react @types/react-dom
    
    # Build frontend
    print_info "Building frontend..."
    npm run build
    
    print_success "Frontend setup completed"
}

configure_nginx() {
    print_step "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/hxnodes <<EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    
    root $PANEL_DIR/frontend/dist;
    index index.html;
    
    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
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

create_panel_services() {
    print_step "Creating panel services..."
    
    # Backend service
    cat > /etc/systemd/system/hxnodes-backend.service <<EOF
[Unit]
Description=hxnodes Backend
After=network.target mariadb.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$PANEL_DIR/backend
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start services
    systemctl daemon-reload
    systemctl enable hxnodes-backend
    systemctl start hxnodes-backend
    
    print_success "Panel services created and started"
}

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

print_panel_summary() {
    print_header
    print_success "hxnodes Panel installation completed!"
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
}

# =============================================================================
# DAEMON INSTALLATION FUNCTIONS
# =============================================================================

install_daemon() {
    print_header
    echo "Installing hxnodes Daemon..."
    echo ""
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Get daemon configuration
    get_daemon_config
    
    # Install daemon dependencies
    install_daemon_dependencies
    
    # Install daemon
    install_daemon_files
    
    # Setup daemon
    setup_daemon
    
    # Create daemon service
    create_daemon_service
    
    print_daemon_summary
}

get_daemon_config() {
    print_step "Daemon Configuration"
    
    read -p "Enter panel URL (e.g., http://panel.yourdomain.com): " PANEL_URL
    read -p "Enter node name [node-$(hostname)]: " NODE_NAME
    NODE_NAME=${NODE_NAME:-node-$(hostname)}
    read -p "Enter daemon port [5001]: " DAEMON_PORT
    DAEMON_PORT=${DAEMON_PORT:-5001}
    
    print_info "Panel URL: $PANEL_URL"
    print_info "Node Name: $NODE_NAME"
    print_info "Daemon Port: $DAEMON_PORT"
}

install_daemon_dependencies() {
    print_step "Installing daemon dependencies..."
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Install Docker (skip if already installed)
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker $SUDO_USER
    fi
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Daemon dependencies installed"
}

install_daemon_files() {
    print_step "Installing daemon files..."
    
    mkdir -p $DAEMON_DIR
    cd $DAEMON_DIR
    
    # Try to clone (works for public repos)
    if git clone $REPO_URL . 2>/dev/null; then
        print_success "Repository cloned successfully"
    else
        # If that fails, try with local files
        print_warning "Repository clone failed, using local files"
        if [[ -d "/root/hosting" ]]; then
            cp -r /root/hosting/* .
            print_success "Local files copied"
        else
            print_error "No local files found. Please ensure the repository is accessible."
            exit 1
        fi
    fi
}

setup_daemon() {
    print_step "Setting up daemon..."
    
    cd $DAEMON_DIR/node-agent
    
    # Install dependencies
    npm install
    
    # Create .env file
    cat > .env <<EOF
AGENT_PORT=$DAEMON_PORT
NODE_NAME=$NODE_NAME
PANEL_URL=$PANEL_URL
EOF
    
    print_success "Daemon setup completed"
}

create_daemon_service() {
    print_step "Creating daemon service..."
    
    # Daemon service
    cat > /etc/systemd/system/hxnodes-daemon.service <<EOF
[Unit]
Description=hxnodes Daemon
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$DAEMON_DIR/node-agent
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable hxnodes-daemon
    systemctl start hxnodes-daemon
    
    print_success "Daemon service created and started"
}

print_daemon_summary() {
    print_header
    print_success "hxnodes Daemon installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "========================"
    echo "Node Name: $NODE_NAME"
    echo "Daemon Port: $DAEMON_PORT"
    echo "Panel URL: $PANEL_URL"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Add this node to your panel at: $PANEL_URL/admin/nodes"
    echo "2. Use the following details:"
    echo "   - Node Name: $NODE_NAME"
    echo "   - IP Address: $(curl -s ifconfig.me)"
    echo "   - Port: $DAEMON_PORT"
    echo ""
    echo -e "${CYAN}Service Status:${NC}"
    systemctl status hxnodes-daemon --no-pager -l
}

# =============================================================================
# UNINSTALLATION FUNCTIONS
# =============================================================================

uninstall_all() {
    print_header
    echo -e "${RED}WARNING: This will completely remove hxnodes from your system!${NC}"
    echo ""
    echo "The following will be deleted:"
    echo "  • All hxnodes files and directories"
    echo "  • Database and all data"
    echo "  • Systemd services"
    echo "  • Nginx configurations"
    echo "  • User accounts and configurations"
    echo ""
    echo -e "${YELLOW}This action cannot be undone!${NC}"
    echo ""
    
    read -p "Are you absolutely sure you want to continue? (type 'YES' to confirm): " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        echo "Uninstallation cancelled."
        show_menu
        return
    fi
    
    echo ""
    read -p "Do you want to backup your data before uninstalling? (y/n): " backup_choice
    
    if [[ $backup_choice =~ ^[Yy]$ ]]; then
        create_backup
    fi
    
    print_step "Starting hxnodes uninstallation..."
    
    stop_and_remove_services
    remove_directories
    remove_database
    remove_nginx_config
    remove_users
    remove_cron_jobs
    remove_docker_containers
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
    
    # Backup daemon files
    if [[ -d "$DAEMON_DIR" ]]; then
        cp -r "$DAEMON_DIR" /tmp/hxnodes_backup/
        print_info "Daemon files backed up"
    fi
    
    # Backup database
    if command -v mysqldump &> /dev/null; then
        mysqldump hxnodes > /tmp/hxnodes_backup/database.sql 2>/dev/null || true
        print_info "Database backed up"
    fi
    
    # Create archive
    tar -czf "$backup_file" -C /tmp hxnodes_backup
    rm -rf /tmp/hxnodes_backup
    
    print_success "Backup created: $backup_file"
    echo "You can restore from this backup if needed."
}

stop_and_remove_services() {
    print_step "Stopping and removing services..."
    
    local services=("hxnodes-backend" "hxnodes-daemon")
    
    for service in "${services[@]}"; do
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

remove_directories() {
    print_step "Removing hxnodes directories..."
    
    local directories=(
        "$PANEL_DIR"
        "$DAEMON_DIR"
        "/var/log/hxnodes"
        "/var/hxnodes/uploads"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_info "Removed directory: $dir"
        fi
    done
    
    print_success "Directories removed"
}

remove_database() {
    print_step "Removing database..."
    
    # Remove all hxnodes users from database
    if command -v mysql &> /dev/null; then
        print_info "Removing hxnodes users from database..."
        mysql -e "DELETE FROM users WHERE email LIKE '%@hxnodes%' OR email LIKE '%@example.com%';" 2>/dev/null || true
        mysql -e "DELETE FROM users WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 DAY);" 2>/dev/null || true
        mysql -e "DROP DATABASE IF EXISTS hxnodes;" 2>/dev/null || true
        mysql -e "DROP USER IF EXISTS 'hxnodes'@'localhost';" 2>/dev/null || true
        print_info "Database users and data removed"
    fi
    
    print_success "Database cleaned"
}

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

remove_users() {
    print_step "Removing hxnodes users..."
    
    # Remove hxnodes user if it exists
    if id "hxnodes" &>/dev/null; then
        userdel -r hxnodes 2>/dev/null || true
        print_info "Removed hxnodes user"
    fi
    
    print_success "Users removed"
}

remove_cron_jobs() {
    print_step "Removing cron jobs..."
    
    # Remove hxnodes cron jobs
    crontab -l 2>/dev/null | grep -v "hxnodes" | crontab - 2>/dev/null || true
    
    print_success "Cron jobs removed"
}

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
# MAIN MENU
# =============================================================================

show_menu() {
    print_header
    echo "What would you like to do?"
    echo ""
    echo "1) Install Panel (Web Interface)"
    echo "2) Install Daemon (Node Agent)"
    echo "3) Uninstall Everything"
    echo "4) Exit"
    echo ""
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1) install_panel ;;
        2) install_daemon ;;
        3) uninstall_all ;;
        4) exit 0 ;;
        *) print_error "Invalid choice"; show_menu ;;
    esac
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    show_menu
}

# Run main function
main "$@" 