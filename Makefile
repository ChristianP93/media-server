# ===========================================
# Media Stack - Makefile
# ===========================================
# Usage: make [target]

.PHONY: help setup start stop restart status logs update health urls creds reset

# Colors
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
CYAN   := \033[0;36m
RED    := \033[0;31m
NC     := \033[0m

# Load .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Determine compose files
ifeq ($(ENABLE_HTTPS),true)
    COMPOSE_FILES := -f docker-compose.yml -f docker-compose.https.yml
else
    COMPOSE_FILES := -f docker-compose.yml
endif

CONFIG_DIR := ./config

# Default target
help:
	@echo ""
	@echo "$(BLUE)Media Stack Management$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup      Run automated setup (first-time configuration)"
	@echo "  start      Start the stack"
	@echo "  stop       Stop the stack"
	@echo "  restart    Restart the stack"
	@echo "  status     Show container status"
	@echo "  logs       Show logs (all services)"
	@echo "  logs-S     Show logs for service S (e.g., make logs-sonarr)"
	@echo "  update     Pull latest images and restart"
	@echo "  health     Check health of all services"
	@echo "  urls       Show service URLs"
	@echo "  creds      Show API keys and credentials"
	@echo "  reset      Stop and remove all data (DANGEROUS)"
	@echo ""

# ===========================================
# Start/Stop Commands
# ===========================================

start:
	@echo "$(GREEN)Starting media stack...$(NC)"
	@docker compose $(COMPOSE_FILES) up -d
	@echo "$(GREEN)Stack started.$(NC)"
	@$(MAKE) -s urls

stop:
	@echo "$(YELLOW)Stopping media stack...$(NC)"
	@docker compose $(COMPOSE_FILES) down
	@echo "$(GREEN)Stack stopped.$(NC)"

restart:
	@echo "$(YELLOW)Restarting media stack...$(NC)"
	@docker compose $(COMPOSE_FILES) restart
	@echo "$(GREEN)Stack restarted.$(NC)"

status:
	@echo ""
	@echo "$(BLUE)Container Status:$(NC)"
	@echo ""
	@docker compose $(COMPOSE_FILES) ps
	@echo ""

logs:
	@echo "$(BLUE)Logs (all services):$(NC)"
	@docker compose $(COMPOSE_FILES) logs -f

logs-%:
	@echo "$(BLUE)Logs for $*:$(NC)"
	@docker compose $(COMPOSE_FILES) logs -f $*

update:
	@echo "$(YELLOW)Pulling latest images...$(NC)"
	@docker compose $(COMPOSE_FILES) pull
	@echo "$(YELLOW)Recreating containers...$(NC)"
	@docker compose $(COMPOSE_FILES) up -d
	@echo "$(GREEN)Update complete.$(NC)"

# ===========================================
# URLs
# ===========================================

urls:
	@echo ""
ifeq ($(ENABLE_HTTPS),true)
	@echo "$(CYAN)HTTPS URLs (via nginx-proxy + Let's Encrypt):$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Plex          https://media.$(DOMAIN)"
	@echo "  Overseerr     https://requests.$(DOMAIN)"
	@echo "  Sonarr        https://sonarr.$(DOMAIN)"
	@echo "  Radarr        https://radarr.$(DOMAIN)"
	@echo "  Prowlarr      https://prowlarr.$(DOMAIN)"
	@echo "  Bazarr        https://bazarr.$(DOMAIN)"
	@echo "  qBittorrent   https://qbit.$(DOMAIN)"
	@echo "  Tautulli      https://stats.$(DOMAIN)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
else
	@echo "$(CYAN)HTTP URLs (via nginx-proxy):$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Plex          http://media.$(DOMAIN)"
	@echo "  Overseerr     http://requests.$(DOMAIN)"
	@echo "  Sonarr        http://sonarr.$(DOMAIN)"
	@echo "  Radarr        http://radarr.$(DOMAIN)"
	@echo "  Prowlarr      http://prowlarr.$(DOMAIN)"
	@echo "  Bazarr        http://bazarr.$(DOMAIN)"
	@echo "  qBittorrent   http://qbit.$(DOMAIN)"
	@echo "  Tautulli      http://stats.$(DOMAIN)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
endif
	@echo "$(BLUE)Direct Local Ports (fallback):$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  nginx-proxy   http://localhost:80"
	@echo "  Plex          http://localhost:32400/web"
	@echo "  Overseerr     http://localhost:5055"
	@echo "  Sonarr        http://localhost:8989"
	@echo "  Radarr        http://localhost:7878"
	@echo "  Prowlarr      http://localhost:9696"
	@echo "  Bazarr        http://localhost:6767"
	@echo "  qBittorrent   http://localhost:8080"
	@echo "  Tautulli      http://localhost:8181"
	@echo "  FlareSolverr  http://localhost:8191"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

# ===========================================
# Health Check
# ===========================================

health:
	@echo ""
	@echo "$(BLUE)Health Check:$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@for service in "nginx-proxy:80" "qbittorrent:8080" "prowlarr:9696" "sonarr:8989" "radarr:7878" "bazarr:6767" "plex:32400" "tautulli:8181" "overseerr:5055" "flaresolverr:8191"; do \
		container=$$(echo $$service | cut -d: -f1); \
		port=$$(echo $$service | cut -d: -f2); \
		if docker ps --format '{{.Names}}' | grep -q "^$${container}$$"; then \
			if [ "$$container" = "plex" ]; then \
				status=$$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$$port/identity" 2>/dev/null || echo "000"); \
			else \
				status=$$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$$port" 2>/dev/null || echo "000"); \
			fi; \
			if echo "$$status" | grep -qE "^(200|302|401|404)$$"; then \
				echo "  $(GREEN)[OK]$(NC)   $$container (port $$port)"; \
			else \
				echo "  $(YELLOW)[WARN]$(NC) $$container (port $$port) - HTTP $$status"; \
			fi; \
		else \
			echo "  $(RED)[DOWN]$(NC) $$container - container not running"; \
		fi; \
	done
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

# ===========================================
# Credentials
# ===========================================

creds:
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)  Media Stack - Credentials$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@if [ -f "$(CONFIG_DIR)/sonarr/config.xml" ]; then \
		key=$$(sed -n 's/.*<ApiKey>\([^<]*\)<\/ApiKey>.*/\1/p' "$(CONFIG_DIR)/sonarr/config.xml"); \
		if [ -n "$$key" ]; then \
			echo "$(GREEN)Sonarr$(NC)"; \
			echo "  API Key: $(YELLOW)$$key$(NC)"; \
			echo ""; \
		fi; \
	fi
	@if [ -f "$(CONFIG_DIR)/radarr/config.xml" ]; then \
		key=$$(sed -n 's/.*<ApiKey>\([^<]*\)<\/ApiKey>.*/\1/p' "$(CONFIG_DIR)/radarr/config.xml"); \
		if [ -n "$$key" ]; then \
			echo "$(GREEN)Radarr$(NC)"; \
			echo "  API Key: $(YELLOW)$$key$(NC)"; \
			echo ""; \
		fi; \
	fi
	@if [ -f "$(CONFIG_DIR)/prowlarr/config.xml" ]; then \
		key=$$(sed -n 's/.*<ApiKey>\([^<]*\)<\/ApiKey>.*/\1/p' "$(CONFIG_DIR)/prowlarr/config.xml"); \
		if [ -n "$$key" ]; then \
			echo "$(GREEN)Prowlarr$(NC)"; \
			echo "  API Key: $(YELLOW)$$key$(NC)"; \
			echo ""; \
		fi; \
	fi
	@if [ -f "$(CONFIG_DIR)/bazarr/config/config.yaml" ]; then \
		key=$$(sed -n 's/.*apikey: *\(.*\)/\1/p' "$(CONFIG_DIR)/bazarr/config/config.yaml" 2>/dev/null); \
		if [ -n "$$key" ]; then \
			echo "$(GREEN)Bazarr$(NC)"; \
			echo "  API Key: $(YELLOW)$$key$(NC)"; \
			echo ""; \
		fi; \
	fi
	@echo "$(GREEN)qBittorrent$(NC)"
	@qbit_user=$$(grep -o 'WebUI\\Username=[^$$]*' "$(CONFIG_DIR)/qbittorrent/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "admin"); \
	if [ -z "$$qbit_user" ]; then qbit_user="admin"; fi; \
	echo "  Username: $(YELLOW)$$qbit_user$(NC)"
	@if [ -f "scripts/setup.env" ]; then \
		qbit_pass=$$(grep -o 'QBIT_PASSWORD="[^"]*"' "scripts/setup.env" 2>/dev/null | cut -d'"' -f2); \
		if [ -n "$$qbit_pass" ]; then \
			echo "  Password: $(YELLOW)$$qbit_pass$(NC)"; \
		else \
			echo "  Password: $(CYAN)(check scripts/setup.env or docker logs qbittorrent)$(NC)"; \
		fi; \
	else \
		echo "  Password: $(CYAN)(check docker logs qbittorrent)$(NC)"; \
	fi
	@echo ""
	@echo "$(GREEN)Plex$(NC)"
	@echo "  URL: $(YELLOW)http://localhost:32400/web$(NC)"
	@echo "  $(CYAN)Login with your Plex account$(NC)"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)  Internal URLs (for Overseerr/service connections)$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  Plex:        $(YELLOW)http://plex:32400$(NC)"
	@echo "  Sonarr:      $(YELLOW)http://sonarr:8989$(NC)"
	@echo "  Radarr:      $(YELLOW)http://radarr:7878$(NC)"
	@echo "  Prowlarr:    $(YELLOW)http://prowlarr:9696$(NC)"
	@echo "  Bazarr:      $(YELLOW)http://bazarr:6767$(NC)"
	@echo "  qBittorrent: $(YELLOW)http://qbittorrent:8080$(NC)"
	@echo ""

# ===========================================
# Setup (First-time configuration)
# ===========================================

setup:
	@echo ""
	@echo "$(GREEN)╔═══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║     Media Stack - Automated Setup                         ║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@# Copy setup.env if not exists
	@if [ ! -f "scripts/setup.env" ]; then \
		echo "$(BLUE)[INFO]$(NC) Creating scripts/setup.env from template..."; \
		cp scripts/setup.env.example scripts/setup.env; \
		echo "$(GREEN)[OK]$(NC) scripts/setup.env created"; \
	fi
	@# Check prerequisites
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  Pre-flight Checks$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) Docker is not installed"; exit 1; }
	@echo "$(GREEN)[OK]$(NC) Docker is installed"
	@docker compose version >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) Docker Compose is not installed"; exit 1; }
	@echo "$(GREEN)[OK]$(NC) Docker Compose is installed"
	@docker info >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) Docker daemon is not running"; exit 1; }
	@echo "$(GREEN)[OK]$(NC) Docker daemon is running"
	@command -v curl >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) curl is required"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(NC) jq is required"; exit 1; }
	@echo "$(GREEN)[OK]$(NC) Required tools (curl, jq) are available"
	@# Create directories
	@echo "$(BLUE)[INFO]$(NC) Creating data directories..."
	@mkdir -p "$(ROOT_DIR)/torrents/incomplete"
	@mkdir -p "$(ROOT_DIR)/media/movies"
	@mkdir -p "$(ROOT_DIR)/media/tv"
	@echo "$(GREEN)[OK]$(NC) Data directories created"
	@# Setup nginx
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  Setting up nginx-proxy$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@mkdir -p $(CONFIG_DIR)/nginx/certs
	@mkdir -p $(CONFIG_DIR)/nginx/vhost.d
	@mkdir -p $(CONFIG_DIR)/nginx/html
	@mkdir -p $(CONFIG_DIR)/nginx/acme
	@mkdir -p $(CONFIG_DIR)/tautulli
	@mkdir -p $(CONFIG_DIR)/plex
	@if [ ! -f "$(CONFIG_DIR)/nginx/custom.conf" ]; then \
		echo "proxy_buffer_size 128k;" > $(CONFIG_DIR)/nginx/custom.conf; \
		echo "proxy_buffers 4 256k;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "proxy_busy_buffers_size 256k;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "client_max_body_size 100m;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "proxy_connect_timeout 60s;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "proxy_send_timeout 60s;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "proxy_read_timeout 60s;" >> $(CONFIG_DIR)/nginx/custom.conf; \
		echo "$(GREEN)[OK]$(NC) nginx custom.conf created"; \
	fi
	@echo "$(GREEN)[OK]$(NC) nginx-proxy setup complete"
	@# Start stack
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  Starting Docker Stack$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)[INFO]$(NC) Pulling latest images..."
	@docker compose $(COMPOSE_FILES) pull
	@echo "$(BLUE)[INFO]$(NC) Starting containers..."
	@docker compose $(COMPOSE_FILES) up -d
	@echo "$(GREEN)[OK]$(NC) Containers started"
	@echo "$(BLUE)[INFO]$(NC) Waiting for services to initialize..."
	@sleep 15
	@# Wait for services
	@for service in "nginx-proxy:80" "flaresolverr:8191" "qbittorrent:8080" "prowlarr:9696" "sonarr:8989" "radarr:7878" "bazarr:6767" "tautulli:8181" "overseerr:5055"; do \
		name=$$(echo $$service | cut -d: -f1); \
		port=$$(echo $$service | cut -d: -f2); \
		echo "$(BLUE)[INFO]$(NC) Waiting for $$name..."; \
		for i in $$(seq 1 30); do \
			if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$$port" 2>/dev/null | grep -qE "200|302|401"; then \
				echo "$(GREEN)[OK]$(NC) $$name is ready"; \
				break; \
			fi; \
			sleep 2; \
		done; \
	done
	@echo "$(BLUE)[INFO]$(NC) Waiting for Plex..."
	@for i in $$(seq 1 30); do \
		if curl -s -o /dev/null -w "%{http_code}" "http://localhost:32400/identity" 2>/dev/null | grep -qE "200|302|401"; then \
			echo "$(GREEN)[OK]$(NC) Plex is ready"; \
			break; \
		fi; \
		sleep 2; \
	done
	@# Print summary
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  Setup Complete!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(GREEN)Your media stack is now running!$(NC)"
	@echo ""
	@$(MAKE) -s urls
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)  Remaining Manual Steps$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  1. Plex: Complete wizard at http://localhost:32400/web"
	@echo "     - Add library: Movies -> /data/media/movies"
	@echo "     - Add library: TV Shows -> /data/media/tv"
	@echo ""
	@echo "  2. Prowlarr: Add indexers at http://localhost:9696"
	@echo "     - See docs/prowlarr-indexers.md for guide"
	@echo ""
	@echo "  3. Overseerr: Complete setup at http://localhost:5055"
	@echo "     - Connect to Plex (URL: http://plex:32400)"
	@echo "     - Add Sonarr (URL: http://sonarr:8989)"
	@echo "     - Add Radarr (URL: http://radarr:7878)"
	@echo ""
	@echo "  4. Sonarr/Radarr/Prowlarr: Create admin accounts"
	@echo ""
	@echo "  Run 'make creds' to see all API keys"
	@echo ""

# ===========================================
# Reset (DANGEROUS)
# ===========================================

reset:
	@echo ""
	@echo "$(RED)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(RED)║  WARNING: This will delete ALL container data!             ║$(NC)"
	@echo "$(RED)║  Including configurations, databases, and settings.        ║$(NC)"
	@echo "$(RED)║  Your media files in ROOT_DIR will NOT be deleted.         ║$(NC)"
	@echo "$(RED)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)Stopping containers...$(NC)"; \
		docker compose $(COMPOSE_FILES) down -v; \
		echo "$(YELLOW)Removing config directories...$(NC)"; \
		rm -rf $(CONFIG_DIR)/prowlarr/*; \
		rm -rf $(CONFIG_DIR)/sonarr/*; \
		rm -rf $(CONFIG_DIR)/radarr/*; \
		rm -rf $(CONFIG_DIR)/bazarr/*; \
		rm -rf $(CONFIG_DIR)/qbittorrent/*; \
		rm -rf $(CONFIG_DIR)/plex/*; \
		rm -rf $(CONFIG_DIR)/overseerr/*; \
		rm -rf $(CONFIG_DIR)/tautulli/*; \
		rm -rf $(CONFIG_DIR)/nginx/certs/*; \
		rm -rf $(CONFIG_DIR)/nginx/acme/*; \
		echo "$(GREEN)Reset complete. Run 'make setup' to reconfigure.$(NC)"; \
	else \
		echo "$(BLUE)Reset cancelled.$(NC)"; \
	fi
