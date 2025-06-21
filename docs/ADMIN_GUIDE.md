# hxnodes Administrator Guide

## Table of Contents
1. [System Overview](#system-overview)
2. [Installation & Setup](#installation--setup)
3. [Configuration Management](#configuration-management)
4. [User Management](#user-management)
5. [Server Management](#server-management)
6. [Node Management](#node-management)
7. [Billing & Financial](#billing--financial)
8. [Monitoring & Logs](#monitoring--logs)
9. [Security](#security)
10. [Backup & Recovery](#backup--recovery)
11. [Maintenance](#maintenance)
12. [Troubleshooting](#troubleshooting)

---

## System Overview

### Architecture
hxnodes is built with a microservices architecture:
- **Web Panel**: React frontend with TypeScript
- **API Backend**: Node.js/Express with TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Node Agents**: Lightweight Node.js agents on game servers
- **Docker**: Containerization for game servers

### Components
- **Main Panel**: Central management interface
- **Node Agents**: Distributed across game servers
- **Database**: Central data storage
- **File Storage**: Server files and backups
- **Payment Gateway**: Integrated billing system

---

## Installation & Setup

### Prerequisites
- Ubuntu 20.04/22.04 or Debian 11+
- 4GB RAM minimum (8GB recommended)
- 50GB storage minimum
- Root access or sudo privileges

### Automated Installation
```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/yourusername/hxnodes/main/install.sh | bash
```

### Manual Installation
1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/hxnodes.git
   cd hxnodes
   ```

2. **Install Dependencies**
   ```bash
   # Backend
   cd backend
   npm install
   
   # Frontend
   cd ../frontend
   npm install
   ```

3. **Configure Environment**
   ```bash
   # Copy example files
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env
   
   # Edit configuration
   nano backend/.env
   nano frontend/.env
   ```

4. **Setup Database**
   ```bash
   cd backend
   npx prisma migrate dev
   npx prisma generate
   ```

5. **Build Frontend**
   ```bash
   cd ../frontend
   npm run build
   ```

6. **Start Services**
   ```bash
   # Backend
   cd ../backend
   npm start
   
   # Frontend (in another terminal)
   cd ../frontend
   npm start
   ```

---

## Configuration Management

### Environment Variables

#### Backend (.env)
```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/hxnodes"

# JWT
JWT_SECRET="your-super-secret-jwt-key"

# Server
PORT=3001
NODE_ENV=production

# File Storage
UPLOAD_PATH="/var/hxnodes/uploads"
MAX_FILE_SIZE=104857600

# Payment Gateways
PAYPAL_CLIENT_ID="your-paypal-client-id"
PAYPAL_CLIENT_SECRET="your-paypal-secret"
UPI_MERCHANT_ID="your-upi-merchant-id"
CRYPTO_API_KEY="your-crypto-api-key"

# Email
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# Node Communication
NODE_AGENT_SECRET="your-node-agent-secret"
```

#### Frontend (.env)
```env
REACT_APP_API_URL="http://localhost:3001"
REACT_APP_WS_URL="ws://localhost:3001"
REACT_APP_PANEL_NAME="hxnodes"
```

### Configuration Files

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # Frontend
    location / {
        root /var/www/hxnodes/frontend/build;
        try_files $uri $uri/ /index.html;
    }
    
    # API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    # WebSocket
    location /ws {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

---

## User Management

### User Roles
- **User**: Standard user with server management
- **Admin**: Full system access
- **Moderator**: Limited admin access

### Creating Admin Users
```sql
-- Via database
UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';

-- Via API
POST /api/admin/users/{userId}/role
{
  "role": "admin"
}
```

### User Operations
- **Suspend User**: Temporarily disable account
- **Delete User**: Permanently remove account
- **Reset Password**: Force password reset
- **View Activity**: Monitor user actions

### Bulk Operations
```bash
# Suspend inactive users
curl -X POST /api/admin/users/bulk-suspend \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"days": 30}'

# Export user data
curl -X GET /api/admin/users/export \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Server Management

### Server Lifecycle
1. **Creation**: User selects plan and pays
2. **Provisioning**: System creates Docker container
3. **Configuration**: Game server setup and configuration
4. **Activation**: Server becomes available to user
5. **Monitoring**: Continuous resource monitoring
6. **Maintenance**: Regular updates and backups
7. **Deletion**: Cleanup when cancelled

### Server Operations
```bash
# Force start server
curl -X POST /api/admin/servers/{serverId}/start \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Force stop server
curl -X POST /api/admin/servers/{serverId}/stop \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# View server logs
curl -X GET /api/admin/servers/{serverId}/logs \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Resource Monitoring
- **CPU Usage**: Real-time CPU utilization
- **Memory Usage**: RAM consumption
- **Disk Usage**: Storage space
- **Network**: Bandwidth usage
- **Processes**: Running processes

### Server Maintenance
```bash
# Update all servers
curl -X POST /api/admin/servers/maintenance/update \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Backup all servers
curl -X POST /api/admin/servers/maintenance/backup \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Node Management

### Node Agent Installation
```bash
# On each game server node
curl -sSL https://raw.githubusercontent.com/yourusername/hxnodes/main/install-node.sh | bash
```

### Node Configuration
```env
# Node agent .env
AGENT_PORT=5001
NODE_NAME=node-1
PANEL_URL=https://panel.yourdomain.com
NODE_AGENT_SECRET=your-secret-key
```

### Node Health Monitoring
- **Connection Status**: Agent connectivity
- **Resource Usage**: Node resource consumption
- **Server Count**: Number of servers on node
- **Performance**: Response times and throughput

### Node Operations
```bash
# Add new node
curl -X POST /api/admin/nodes \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "node-2",
    "ip": "192.168.1.100",
    "port": 5001,
    "location": "US-East"
  }'

# Remove node
curl -X DELETE /api/admin/nodes/{nodeId} \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Load Balancing
- **Automatic Distribution**: New servers distributed across nodes
- **Manual Assignment**: Force server to specific node
- **Load Balancing**: Balance servers based on node capacity

---

## Billing & Financial

### Payment Processing
- **UPI**: Indian payment system integration
- **PayPal**: International payment processing
- **Cryptocurrency**: Bitcoin, Ethereum support
- **Manual Payments**: Admin-approved payments

### Invoice Management
```bash
# Generate invoice
curl -X POST /api/admin/billing/invoices \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "user-id",
    "amount": 29.99,
    "description": "Premium Plan - Monthly"
  }'

# Mark invoice as paid
curl -X PUT /api/admin/billing/invoices/{invoiceId}/status \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"status": "paid"}'
```

### Financial Reports
- **Revenue Reports**: Monthly/quarterly revenue
- **Payment Analytics**: Payment method usage
- **Refund Management**: Process refunds
- **Tax Reports**: Generate tax documents

### Subscription Management
```bash
# Extend subscription
curl -X POST /api/admin/subscriptions/{subscriptionId}/extend \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"months": 3}'

# Cancel subscription
curl -X POST /api/admin/subscriptions/{subscriptionId}/cancel \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Monitoring & Logs

### System Monitoring
```bash
# Check system status
curl -X GET /api/admin/system/status \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# View system metrics
curl -X GET /api/admin/system/metrics \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Log Management
- **Application Logs**: Backend and frontend logs
- **Server Logs**: Individual game server logs
- **Node Logs**: Node agent logs
- **Error Logs**: System error tracking

### Log Rotation
```bash
# Configure log rotation
cat > /etc/logrotate.d/hxnodes <<EOF
/var/log/hxnodes/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload hxnodes-backend
    endscript
}
EOF
```

### Alerting
- **Email Alerts**: Critical system notifications
- **Discord Webhooks**: Real-time alerts
- **SMS Alerts**: Emergency notifications
- **Dashboard Alerts**: In-panel notifications

---

## Security

### Access Control
- **JWT Authentication**: Secure token-based auth
- **Role-Based Access**: Granular permissions
- **API Rate Limiting**: Prevent abuse
- **IP Whitelisting**: Restrict access

### Data Protection
- **Encryption**: Data at rest and in transit
- **Backup Encryption**: Encrypted backups
- **PII Protection**: Personal data handling
- **GDPR Compliance**: Data privacy compliance

### Security Monitoring
```bash
# Check for suspicious activity
curl -X GET /api/admin/security/audit \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# View failed login attempts
curl -X GET /api/admin/security/failed-logins \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Security Hardening
```bash
# Update system packages
apt update && apt upgrade -y

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install security tools
apt install -y fail2ban rkhunter
```

---

## Backup & Recovery

### Backup Strategy
- **Database Backups**: Daily automated backups
- **File Backups**: Server files and configurations
- **Configuration Backups**: System configurations
- **Disaster Recovery**: Complete system recovery

### Automated Backups
```bash
#!/bin/bash
# /opt/hxnodes/scripts/backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/hxnodes"

# Database backup
pg_dump hxnodes > $BACKUP_DIR/db_$DATE.sql

# File backup
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/hxnodes/uploads

# Configuration backup
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/hxnodes

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

### Recovery Procedures
```bash
# Database recovery
psql hxnodes < /var/backups/hxnodes/db_20231201_120000.sql

# File recovery
tar -xzf /var/backups/hxnodes/files_20231201_120000.tar.gz -C /

# Configuration recovery
tar -xzf /var/backups/hxnodes/config_20231201_120000.tar.gz -C /
```

### Backup Monitoring
```bash
# Check backup status
curl -X GET /api/admin/backups/status \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Test backup restoration
curl -X POST /api/admin/backups/test-restore \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Maintenance

### Regular Maintenance Tasks
- **System Updates**: Weekly security updates
- **Database Optimization**: Monthly database maintenance
- **Log Cleanup**: Weekly log rotation
- **Backup Verification**: Daily backup checks

### Maintenance Schedule
```bash
# Weekly maintenance script
#!/bin/bash
# /opt/hxnodes/scripts/weekly-maintenance.sh

echo "Starting weekly maintenance..."

# Update system packages
apt update && apt upgrade -y

# Clean old logs
find /var/log/hxnodes -name "*.log" -mtime +7 -delete

# Optimize database
psql hxnodes -c "VACUUM ANALYZE;"

# Check disk space
df -h | grep -E "Use%|/$"

# Restart services
systemctl restart hxnodes-backend
systemctl restart hxnodes-frontend

echo "Weekly maintenance completed."
```

### Performance Optimization
- **Database Indexing**: Optimize query performance
- **Caching**: Implement Redis caching
- **CDN**: Use CDN for static assets
- **Load Balancing**: Distribute load across servers

### Monitoring Maintenance
```bash
# Check system health
curl -X GET /api/admin/maintenance/health \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Run diagnostics
curl -X POST /api/admin/maintenance/diagnostics \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Troubleshooting

### Common Issues

#### Database Connection Issues
```bash
# Check database status
systemctl status postgresql

# Test connection
psql -h localhost -U hxnodes -d hxnodes

# Check logs
tail -f /var/log/postgresql/postgresql-*.log
```

#### Node Agent Issues
```bash
# Check node agent status
systemctl status hxnodes-node-agent

# View node agent logs
journalctl -u hxnodes-node-agent -f

# Test node connectivity
curl -X GET http://node-ip:5001/health
```

#### Payment Issues
```bash
# Check payment gateway status
curl -X GET /api/admin/billing/gateways/status \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# View payment logs
curl -X GET /api/admin/billing/logs \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Diagnostic Tools
```bash
# System diagnostics
curl -X GET /api/admin/diagnostics/system \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Network diagnostics
curl -X GET /api/admin/diagnostics/network \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Performance diagnostics
curl -X GET /api/admin/diagnostics/performance \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Emergency Procedures
```bash
# Emergency shutdown
systemctl stop hxnodes-backend
systemctl stop hxnodes-frontend

# Emergency recovery
/opt/hxnodes/scripts/emergency-recovery.sh

# Contact support
curl -X POST /api/admin/emergency/alert \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"message": "Emergency situation detected"}'
```

---

## Support Resources

### Documentation
- **User Manual**: Complete user documentation
- **API Documentation**: REST API reference
- **Developer Guide**: Development documentation
- **FAQ**: Frequently asked questions

### Support Channels
- **Email**: admin@yourdomain.com
- **Discord**: Join our Discord server
- **GitHub Issues**: Bug reports and feature requests
- **Emergency**: 24/7 emergency support

### Training Resources
- **Video Tutorials**: Step-by-step guides
- **Webinars**: Live training sessions
- **Certification**: Admin certification program
- **Community**: User community forum

---

*This guide is regularly updated. For the latest version, check the GitHub repository.* 