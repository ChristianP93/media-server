# Media Automation Stack (IaC)

## Project Overview

This project implements a complete media automation stack using an Infrastructure as Code (IaC) approach via Docker Compose.

The goal is to orchestrate downloading, management, renaming, and enrichment of media with minimal manual intervention.

---

## Stack Components

| Service | Description | Port |
|---------|-------------|------|
| **nginx-proxy** | Automatic reverse proxy with Docker discovery | 80/443 |
| **Plex** | Media server for streaming | 32400 |
| **Overseerr** | Media request frontend | 5055 |
| **Prowlarr** | Indexer manager (torrent trackers) | 9696 |
| **Sonarr** | TV Shows management (monitoring, download, rename) | 8989 |
| **Radarr** | Movies management (monitoring, download, rename) | 7878 |
| **Bazarr** | Automatic subtitle management and download | 6767 |
| **qBittorrent** | Torrent download client | 8080 |
| **Tautulli** | Plex statistics and monitoring | 8181 |
| **FlareSolverr** | Cloudflare bypass for protected indexers | 8191 |

---

## Configuration (Infrastructure as Code)

The entire infrastructure configuration is defined in three files:
- `docker-compose.yml` - Base stack (HTTP)
- `docker-compose.https.yml` - HTTPS override (Let's Encrypt)
- `.env` - Environment variables

### 1. Directory Structure

To ensure hardlinks work (instant file movement without space duplication), a single volume structure is essential.

```
/home/user/media-stack/
├── .env                    # Environment variables
├── docker-compose.yml      # Base stack
├── docker-compose.https.yml # HTTPS override (optional)
├── config/                 # Persistent app data
│   ├── nginx/
│   ├── plex/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── bazarr/
│   ├── qbittorrent/
│   ├── overseerr/
│   └── tautulli/
├── docs/
│   └── prowlarr-indexers.md  # Guide for adding indexers
├── scripts/
│   └── setup.env.example  # Setup configuration template
└── Makefile               # Stack management commands
```

### 2. The `.env` File

Copy the example file and customize it:

```bash
cp .env.example .env
```

Main contents:

```env
# User identifiers (run 'id' in terminal)
PUID=1000
PGID=1000

# Timezone
TZ=Europe/Rome

# Base data directory
ROOT_DIR=/path/to/your/media-data

# Domain (for local development use: media.local)
DOMAIN=media.local

# HTTPS (optional - requires public domain)
ENABLE_HTTPS=false
ACME_EMAIL=your-email@example.com

# Plex Claim Token (get from https://www.plex.tv/claim/)
PLEX_CLAIM=
```

---

## Getting Started

### Quick Start (Local Development)

```bash
# 1. Clone the repository
git clone git@github.com:ChristianP93/media-server.git
cd auto-torrent

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your values

# 3. Start the stack
docker compose up -d
```

### Start with Automated Setup

```bash
make setup
```

This will automatically create `scripts/setup.env` from the template if it doesn't exist.

### HTTPS Mode (Production)

To enable HTTPS with Let's Encrypt certificates:

```bash
# 1. Configure .env
ENABLE_HTTPS=true
DOMAIN=yourdomain.com
ACME_EMAIL=your-email@example.com

# 2. Start with HTTPS override
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
```

---

## Local Configuration (Development)

To access services via hostname (e.g., `sonarr.media.local`) instead of ports, you need to configure the `/etc/hosts` file.

### 1. Edit /etc/hosts

```bash
sudo nano /etc/hosts
```

### 2. Add these lines

```
# Media Stack - Local Development
127.0.0.1   sonarr.media.local
127.0.0.1   radarr.media.local
127.0.0.1   prowlarr.media.local
127.0.0.1   bazarr.media.local
127.0.0.1   qbit.media.local
127.0.0.1   media.media.local
127.0.0.1   requests.media.local
127.0.0.1   stats.media.local
```

### 3. Save and verify

```bash
ping sonarr.media.local
```

Now you can access:
- http://sonarr.media.local (instead of localhost:8989)
- http://radarr.media.local (instead of localhost:7878)
- http://media.media.local (Plex instead of localhost:32400)

**Note:** Services remain accessible via direct ports as a fallback.

---

## Stack Management

Use `make` to manage the stack:

```bash
make setup        # Run automated first-time setup
make start        # Start the stack
make stop         # Stop the stack
make restart      # Restart the stack
make status       # Container status
make logs         # View all logs
make logs-sonarr  # Logs for a specific service
make update       # Update images
make health       # Health check all services
make urls         # Show all URLs
make creds        # Show API keys and credentials
make reset        # Full reset (CAUTION!)
```

---

## Post-Deploy Configuration

### 1. Plex

1. Go to http://localhost:32400/web
2. Claim the server (requires PLEX_CLAIM on first run)
3. Add libraries:
   - Movies → `/data/media/movies`
   - TV Shows → `/data/media/tv`

### 2. qBittorrent

- URL: http://localhost:8080
- Default: `admin` / check logs for temporary password or run `make creds`
- Set download path to: `/data/torrents`

### 3. Sonarr/Radarr

- Configure "Root Folder" for media:
  - Sonarr: `/data/media/tv`
  - Radarr: `/data/media/movies`
- Moving from `/data/torrents` will be instant (hardlinks)

### 4. Prowlarr

- Add torrent indexers (see [docs/prowlarr-indexers.md](docs/prowlarr-indexers.md))
- Go to `Settings > Apps` and connect Sonarr and Radarr (Full Sync)

### 5. Bazarr

- Connect to Sonarr and Radarr
- Configure subtitle languages

### 6. Overseerr

- Connect to Plex (internal URL: `http://plex:32400`)
- Add Sonarr (internal URL: `http://sonarr:8989`)
- Add Radarr (internal URL: `http://radarr:7878`)

### 7. Tautulli

- Connect to Plex (internal URL: `http://plex:32400`)

---

## Architecture

### Reverse Proxy (nginx-proxy)

The stack uses [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for automatic hostname-based routing:

- Automatically discovers Docker containers via labels
- Uses `VIRTUAL_HOST` for routing
- Supports WebSocket for real-time applications
- With `docker-compose.https.yml`: automatic SSL certificates via Let's Encrypt

### Data Structure

```
${ROOT_DIR}/
├── torrents/           # Downloads in progress
│   ├── incomplete/     # Incomplete downloads
│   ├── tv/            # Completed TV shows
│   └── movies/        # Completed movies
└── media/
    ├── tv/            # TV Shows library (Sonarr)
    └── movies/        # Movies library (Radarr)
```

### Network

All services communicate via the Docker network `media-network`:

- Services reach each other by container name (e.g., `http://sonarr:8989`)
- nginx-proxy exposes services externally
- FlareSolverr is only accessible internally

---

## Troubleshooting

### Services don't respond via hostname

1. Verify nginx-proxy is running: `docker ps | grep nginx-proxy`
2. Check logs: `docker logs nginx-proxy`
3. Verify `/etc/hosts` for local development

### Plex won't connect

1. Make sure you have a valid PLEX_CLAIM (expires in 4 minutes)
2. Verify port 32400 is reachable
3. For remote claim: http://localhost:32400/web

### Hardlinks not working

1. Verify all services use the same `/data` volume
2. Check permissions: PUID/PGID must be consistent
3. Filesystem must support hardlinks (no NTFS/exFAT)

### SSL certificates not generated

1. Domain must point to the server (DNS A/CNAME record)
2. Ports 80 and 443 must be accessible from outside
3. Check logs: `docker logs acme-companion`

---

## Compatibility

- **macOS**: Intel and Apple Silicon (M1/M2/M3)
- **Linux**: AMD64 and ARM64
- **Windows**: WSL2 with Docker Desktop

LinuxServer.io images natively support multiple architectures.
