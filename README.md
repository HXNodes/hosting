# hxnodes - Game Server Management Panel

A modern, feature-rich game server management panel with integrated billing, multi-node support, and real-time monitoring.

## 🚀 Features

- **Game Server Management**: Deploy, manage, and monitor game servers
- **Integrated Billing**: UPI, PayPal, and cryptocurrency payments
- **Multi-Node Support**: Distribute servers across multiple nodes
- **Real-Time Monitoring**: Live resource usage and performance metrics
- **File Manager**: Web-based file management for server files
- **Live Console**: Real-time terminal access to servers
- **Affiliate System**: Built-in referral and commission tracking
- **Admin Panel**: Comprehensive administrative controls
- **API Access**: RESTful API for integrations
- **Security**: JWT authentication, role-based access, and security hardening

## 🛠️ Technology Stack

- **Frontend**: React + TypeScript + TailwindCSS
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Containerization**: Docker for game servers
- **Web Server**: Nginx
- **Authentication**: JWT tokens
- **Real-time**: WebSocket connections

## 📋 Requirements

- **OS**: Ubuntu 20.04/22.04 or Debian 11+
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 50GB minimum
- **Root Access**: Required for installation

## 🚀 Quick Installation

### Single Command Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HXNodes/hosting/main/install.sh)
```

### What the Installer Does

The installer provides a Pterodactyl-style interface with three main options:

1. **Install Panel** - Web interface for managing servers
2. **Install Daemon** - Node agent for game servers
3. **Uninstall Everything** - Complete system cleanup

### Panel Installation

When you choose to install the panel, you'll only need to provide:

- **Domain/IP Address** (auto-detected as default)
- **Admin Email** (for login)
- **Admin Password** (for login)

Everything else is automatically configured:
- ✅ Database setup with secure passwords
- ✅ JWT secret generation
- ✅ Dependencies installation
- ✅ Service configuration
- ✅ Security hardening

### Daemon Installation

For game server nodes, you'll need:

- **Panel URL** (where your main panel is hosted)
- **Node Name** (auto-detected as default)
- **Daemon Port** (default: 5001)

## 📁 Directory Structure

```
/var/www/hxnodes/          # Panel files (web interface)
├── backend/               # Backend API
├── frontend/              # Frontend React app
└── node-agent/            # Node agent files

/opt/hxnodes-daemon/       # Daemon files (node agents)
└── node-agent/            # Node agent application

/etc/systemd/system/       # Systemd services
├── hxnodes-backend.service
└── hxnodes-daemon.service
```

## 🔧 Manual Installation

If you prefer manual installation:

### 1. Clone Repository
```bash
git clone https://github.com/HXNodes/hosting.git
cd hosting
```

### 2. Install Dependencies
```bash
# Backend
cd backend
npm install

# Frontend
cd ../frontend
npm install
```

### 3. Configure Environment
```bash
# Backend .env
cp backend/.env.example backend/.env
# Edit with your configuration

# Frontend .env
cp frontend/.env.example frontend/.env
# Edit with your configuration
```

### 4. Setup Database
```bash
cd backend
npx prisma migrate deploy
npx prisma generate
```

### 5. Build Frontend
```bash
cd ../frontend
npm run build
```

## 🗑️ Uninstallation

### Complete Uninstallation
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HXNodes/hosting/main/install.sh)
# Choose option 3: Uninstall Everything
```

### What Gets Removed
- ✅ All hxnodes files and directories
- ✅ Database and all user data
- ✅ Systemd services
- ✅ Nginx configurations
- ✅ Docker containers and images
- ✅ User accounts and cron jobs

### Backup Before Uninstalling
The uninstaller offers to create a backup before removing everything, including:
- Panel and daemon files
- Database dump
- Configuration files

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
PORT=4000
DATABASE_URL=mysql://user:password@localhost:3306/hxnodes
JWT_SECRET=your-jwt-secret
RAZORPAY_KEY_ID=your-razorpay-key
RAZORPAY_KEY_SECRET=your-razorpay-secret
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-secret
CRYPTO_API_KEY=your-crypto-api-key
BASE_URL=http://yourdomain.com
```

#### Frontend (.env)
```env
VITE_API_BASE_URL=/api
VITE_PANEL_NAME=hxnodes
```

### Nginx Configuration
The installer automatically creates Nginx configuration for:
- Static file serving
- API proxy
- WebSocket support
- SSL (optional)

## 🚀 Usage

### Accessing the Panel
1. Open your domain/IP in a browser
2. Register with your admin email
3. Login and start managing servers

### Adding Nodes
1. Run the installer on a game server
2. Choose "Install Daemon"
3. Provide your panel URL
4. Add the node in your panel's admin section

### Creating Servers
1. Go to your panel dashboard
2. Click "Create Server"
3. Select a plan and game type
4. Complete payment
5. Server will be automatically provisioned

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-Based Access**: Granular permissions for users
- **API Rate Limiting**: Prevents abuse
- **Firewall Configuration**: UFW with secure defaults
- **Fail2ban**: Protection against brute force attacks
- **SSL Support**: Let's Encrypt integration
- **Database Security**: Secure MariaDB configuration

## 📊 Monitoring

### Built-in Monitoring
- Real-time resource usage (CPU, RAM, disk)
- Server performance metrics
- Network bandwidth monitoring
- Process monitoring

### External Monitoring
```bash
# Add to crontab for system monitoring
*/5 * * * * /opt/hxnodes/scripts/monitoring.sh
```

## 🔄 Backup & Recovery

### Automated Backups
```bash
# Add to crontab for daily backups
0 2 * * * /opt/hxnodes/scripts/backup.sh
```

### Manual Backup
```bash
/opt/hxnodes/scripts/backup.sh
```

### Restore from Backup
```bash
/opt/hxnodes/scripts/backup.sh restore /path/to/backup/file
```

## 🛠️ Maintenance

### Service Management
```bash
# Check service status
systemctl status hxnodes-backend
systemctl status hxnodes-daemon

# Restart services
systemctl restart hxnodes-backend
systemctl restart hxnodes-daemon

# View logs
journalctl -u hxnodes-backend -f
journalctl -u hxnodes-daemon -f
```

### Database Maintenance
```bash
# Access database
mysql -u hxnodes -p hxnodes

# Run migrations
cd /var/www/hxnodes/backend
npx prisma migrate deploy
```

## 📚 Documentation

- **[User Manual](docs/USER_MANUAL.md)** - Complete user guide
- **[Admin Guide](docs/ADMIN_GUIDE.md)** - Administrative documentation
- **[Deployment Guide](docs/DEPLOY.md)** - Production deployment guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the docs folder
- **Issues**: Report bugs on GitHub
- **Discussions**: Use GitHub Discussions for questions

## 🚀 Quick Start Commands

```bash
# Install panel
bash <(curl -fsSL https://raw.githubusercontent.com/HXNodes/hosting/main/install.sh)
# Choose option 1

# Install daemon on game server
bash <(curl -fsSL https://raw.githubusercontent.com/HXNodes/hosting/main/install.sh)
# Choose option 2

# Uninstall everything
bash <(curl -fsSL https://raw.githubusercontent.com/HXNodes/hosting/main/install.sh)
# Choose option 3
```

---

**hxnodes** - Modern game server management made simple. 