#!/bin/bash
set -e

# --- Helper Functions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_command() {
    if ! command -v $1 &> /dev/null
    then
        echo -e "${YELLOW}Warning: $1 is not installed. Please install it to continue.${NC}"
        exit 1
    fi
}

echo -e "${GREEN}Welcome to the hxnodes Interactive Setup!${NC}"
echo "This script will guide you through setting up the entire platform."
echo "------------------------------------------------------------------"

# --- 1. Dependency Check ---
echo "Checking for required dependencies (docker, docker-compose, npm, nginx)..."
check_command docker
check_command docker-compose
check_command npm
check_command nginx
echo "All dependencies found."
echo "------------------------------------------------------------------"

# --- 2. Gather Configuration ---
echo "Please provide the following configuration values:"

read -p "Enter your domain name (e.g., hxnodes.com): " DOMAIN_NAME
read -p "Enter Database User [hxadmin]: " DB_USER
DB_USER=${DB_USER:-hxadmin}
read -sp "Enter Database Password [hxpass]: " DB_PASS
DB_PASS=${DB_PASS:-hxpass}
echo
read -p "Enter Database Name [hxnodes]: " DB_NAME
DB_NAME=${DB_NAME:-hxnodes}
read -sp "Enter a strong JWT Secret [randomly generated]: " JWT_SECRET
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
echo
read -p "Enter Razorpay Key ID (optional): " RAZORPAY_KEY_ID
read -p "Enter Razorpay Key Secret (optional): " RAZORPAY_KEY_SECRET
read -p "Enter PayPal Client ID (optional): " PAYPAL_CLIENT_ID
read -p "Enter PayPal Client Secret (optional): " PAYPAL_CLIENT_SECRET
read -p "Enter Crypto API Key (optional): " CRYPTO_API_KEY
read -p "Enter Node Agent Port [5001]: " AGENT_PORT
AGENT_PORT=${AGENT_PORT:-5001}
read -p "Enter Node Name [node1]: " NODE_NAME
NODE_NAME=${NODE_NAME:-node1}
echo "------------------------------------------------------------------"

# --- 3. Generate .env Files ---
echo "Generating .env files..."

# Backend .env
cat > backend/.env <<EOF
PORT=4000
DATABASE_URL=postgres://${DB_USER}:${DB_PASS}@db:5432/${DB_NAME}
JWT_SECRET=${JWT_SECRET}
RAZORPAY_KEY_ID=${RAZORPAY_KEY_ID}
RAZORPAY_KEY_SECRET=${RAZORPAY_KEY_SECRET}
PAYPAL_CLIENT_ID=${PAYPAL_CLIENT_ID}
PAYPAL_CLIENT_SECRET=${PAYPAL_CLIENT_SECRET}
CRYPTO_API_KEY=${CRYPTO_API_KEY}
BASE_URL=http://${DOMAIN_NAME}
EOF

# Frontend .env
cat > frontend/.env <<EOF
VITE_API_BASE_URL=/api
EOF

# Node Agent .env
cat > node-agent/.env <<EOF
AGENT_PORT=${AGENT_PORT}
NODE_NAME=${NODE_NAME}
EOF

# Docker Compose .env for DB
cat > .env <<EOF
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_DB=${DB_NAME}
EOF

echo ".env files created successfully."
echo "------------------------------------------------------------------"

# --- 4. Install, Migrate, and Build ---
echo "Installing dependencies, running migrations, and building projects..."

echo "Backend setup..."
cd backend
npm install
npx prisma migrate deploy
cd ..

echo "Frontend setup..."
cd frontend
npm install
npm run build
cd ..

echo "Node Agent setup..."
cd node-agent
npm install
cd ..

echo "All projects are set up."
echo "------------------------------------------------------------------"

# --- 5. Docker and Nginx Setup ---
echo "Building and launching Docker containers..."
docker-compose up -d --build

echo "Configuring Nginx reverse proxy..."
NGINX_CONF="/etc/nginx/sites-available/hxnodes"
cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api/ {
        proxy_pass http://localhost:4000/api/;
    }

    location /ws/ {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

if [ -f "/etc/nginx/sites-enabled/hxnodes" ]; then
    rm /etc/nginx/sites-enabled/hxnodes
fi
ln -s $NGINX_CONF /etc/nginx/sites-enabled/

echo "Reloading Nginx..."
nginx -t # Test config
nginx -s reload

echo "------------------------------------------------------------------"

# --- 6. SSL Setup (Optional) ---
read -p "Do you want to set up SSL with Let's Encrypt (Certbot)? (y/n): " SETUP_SSL
if [[ "$SETUP_SSL" == "y" || "$SETUP_SSL" == "Y" ]]; then
    echo "Setting up SSL..."
    check_command certbot
    certbot --nginx -d ${DOMAIN_NAME} --non-interactive --agree-tos -m admin@${DOMAIN_NAME}
    echo "SSL setup complete."
else
    echo "Skipping SSL setup."
fi

echo "------------------------------------------------------------------"
echo -e "${GREEN}🎉 All done! Your platform is running at: http://${DOMAIN_NAME}${NC}"
echo "If you set up SSL, it is also available at: https://${DOMAIN_NAME}"
echo "------------------------------------------------------------------" 