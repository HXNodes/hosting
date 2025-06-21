#!/bin/bash

# =============================================================================
# hxnodes Node Agent Installation Script
# =============================================================================
# This script installs the hxnodes node agent on Ubuntu/Debian servers
# Use this script to add game server nodes to your hxnodes panel
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
NODE_DIR="/opt/hxnodes-node"
REPO_URL="https://github.com/yourusername/hxnodes.git"
PANEL_URL=""
NODE_NAME=""
AGENT_PORT="5001"

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  hxnodes Node Agent Installation Script"
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
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Installing Docker..."
        install_docker
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

install_docker() {
    print_step "Installing Docker..."
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker and Docker Compose installed"
}

install_nodejs() {
    print_step "Installing Node.js and npm..."
    
    # Install Node.js 18.x
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    print_success "Node.js $(node --version) and npm $(npm --version) installed"
}

install_dependencies() {
    print_step "Installing dependencies..."
    
    update_system
    install_nodejs
    
    # Install additional tools
    apt install -y curl git wget
    
    print_success "All dependencies installed"
}

# =============================================================================
# NODE AGENT SETUP
# =============================================================================

get_node_config() {
    print_step "Node Configuration"
    
    read -p "Enter your panel URL (e.g., https://panel.yourdomain.com): " PANEL_URL
    read -p "Enter node name [node-$(hostname)]: " NODE_NAME
    NODE_NAME=${NODE_NAME:-node-$(hostname)}
    read -p "Enter agent port [5001]: " AGENT_PORT
    AGENT_PORT=${AGENT_PORT:-5001}
}

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
AGENT_PORT=$AGENT_PORT
NODE_NAME=$NODE_NAME
PANEL_URL=$PANEL_URL
EOF
    
    print_success "Node Agent installed"
}

# =============================================================================
# SYSTEMD SERVICE
# =============================================================================

create_systemd_service() {
    print_step "Creating systemd service..."
    
    cat > /etc/systemd/system/hxnodes-node-agent.service <<EOF
[Unit]
Description=hxnodes Node Agent
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$NODE_DIR/node-agent
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable hxnodes-node-agent
    systemctl start hxnodes-node-agent
    
    print_success "Systemd service created and started"
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
    ufw allow $AGENT_PORT/tcp
    ufw --force enable
    
    print_success "Security configured"
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================

print_final_summary() {
    print_header
    print_success "Node Agent installation completed!"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "========================"
    echo "Node Name: $NODE_NAME"
    echo "Agent Port: $AGENT_PORT"
    echo "Panel URL: $PANEL_URL"
    echo "Installation Directory: $NODE_DIR"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Add this node to your panel at: $PANEL_URL/admin/nodes"
    echo "2. Use the following details:"
    echo "   - Node Name: $NODE_NAME"
    echo "   - IP Address: $(curl -s ifconfig.me)"
    echo "   - Port: $AGENT_PORT"
    echo "3. Test the connection from your panel"
    echo ""
    echo -e "${CYAN}Service Status:${NC}"
    systemctl status hxnodes-node-agent --no-pager -l
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "Start service: systemctl start hxnodes-node-agent"
    echo "Stop service: systemctl stop hxnodes-node-agent"
    echo "View logs: journalctl -u hxnodes-node-agent -f"
    echo "Restart service: systemctl restart hxnodes-node-agent"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header
    
    detect_environment
    install_dependencies
    get_node_config
    install_node_agent
    create_systemd_service
    setup_security
    print_final_summary
}

# Run main function
main "$@" 