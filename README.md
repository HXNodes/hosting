# hxnodes

A modern, unified platform for game server management and billing.

## Project Structure

- `backend/` — Node.js/Express API (TypeScript, PostgreSQL, Prisma)
- `frontend/` — React.js + TailwindCSS client
- `node-agent/` — Lightweight Node.js service for Docker orchestration on each node
- `docker-compose.yml` — Orchestrates backend, frontend, database, and node-agent for local development
- `docs/` — Documentation and architecture guides

## Quick Start (Development)

1. **Clone the repo**
2. **Install dependencies** in each directory:
   - `cd backend && npm install`
   - `cd frontend && npm install`
   - `cd node-agent && npm install`
3. **Configure environment variables** (see `.env.example` in each directory)
4. **Run with Docker Compose:**
   - `docker-compose up --build`

## Modules

### Backend
- REST API for all platform features
- Auth (JWT, 2FA), RBAC, billing, server management
- Connects to PostgreSQL via Prisma ORM

### Frontend
- Modern React app with TailwindCSS
- Client dashboard, server controls, billing, admin panel

### Node Agent
- Runs on each physical/virtual node
- Exposes secure API for Docker container orchestration

---

For detailed docs, see the `docs/` directory. 