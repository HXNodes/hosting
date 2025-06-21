# Deployment Guide for hxnodes

## Prerequisites
- Ubuntu 20.04+ (or similar Linux)
- Docker & Docker Compose
- Node.js 18+
- Nginx (for reverse proxy)

## 1. Clone the Repository
```
git clone <your-repo-url>
cd hxnodes
```

## 2. Configure Environment Variables
- Copy `.env.example` to `.env` in each of `backend/`, `frontend/`, and `node-agent/`.
- Fill in all required secrets and API keys.

## 3. Run the Setup Script
```
sudo ./setup.sh
```

## 4. Set Up SSL (Recommended)
Use Certbot for Let's Encrypt:
```
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## 5. Access the Platform
Visit `http://yourdomain.com` in your browser.

---

For troubleshooting, logs, and advanced configuration, see the README and comments in `setup.sh`. 