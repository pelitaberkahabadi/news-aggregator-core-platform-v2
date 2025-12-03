.PHONY: help build up down restart logs ps shell shell-www db migrate composer-install composer-update cache-clear config-clear health backup restore clean

# Default target
help:
	@echo "News Aggregator Docker Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make build           - Build Docker images"
	@echo "  make up              - Start all containers"
	@echo "  make down            - Stop all containers"
	@echo "  make restart         - Restart all containers"
	@echo "  make logs            - View logs (all services)"
	@echo "  make logs-app        - View app container logs"
	@echo "  make logs-nginx      - View nginx container logs"
	@echo "  make logs-db         - View database container logs"
	@echo "  make ps              - Show container status"
	@echo "  make shell           - Access app container shell"
	@echo "  make shell-www       - Access app container as www user"
	@echo "  make db              - Access PostgreSQL shell"
	@echo "  make migrate         - Run database migrations"
	@echo "  make composer-install - Install PHP dependencies"
	@echo "  make composer-update  - Update PHP dependencies"
	@echo "  make cache-clear     - Clear application cache"
	@echo "  make config-clear    - Clear configuration cache"
	@echo "  make health          - Check containers health"
	@echo "  make backup          - Backup database"
	@echo "  make restore         - Restore database from backup"
	@echo "  make clean           - Remove containers and volumes"

# Build Docker images
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@make ps

# Stop all services
down:
	docker-compose down

# Restart all services
restart:
	docker-compose restart

# View logs from all services
logs:
	docker-compose logs -f

# View app logs
logs-app:
	docker-compose logs -f app

# View nginx logs
logs-nginx:
	docker-compose logs -f nginx

# View database logs
logs-db:
	docker-compose logs -f postgres

# Show container status
ps:
	docker-compose ps

# Access app container shell
shell:
	docker-compose exec app sh

# Access app container as www user
shell-www:
	docker-compose exec -u www app sh

# Access PostgreSQL shell
db:
	docker-compose exec postgres psql -U mediakau_news -d mediakau_news_db

# Run database migrations
migrate:
	docker-compose exec app php artisan migrate

# Install PHP dependencies
composer-install:
	docker-compose exec app composer install

# Update PHP dependencies
composer-update:
	docker-compose exec app composer update

# Clear application cache
cache-clear:
	docker-compose exec app php artisan cache:clear
	@echo "Cache cleared successfully!"

# Clear configuration cache
config-clear:
	docker-compose exec app php artisan config:clear
	@echo "Configuration cache cleared successfully!"

# Check health of all containers
health:
	@echo "Checking container health..."
	@docker-compose ps
	@echo ""
	@echo "Testing API health endpoint..."
	@curl -f http://localhost/health || echo "Health check failed!"

# Backup database
backup:
	@mkdir -p backups
	docker-compose exec postgres pg_dump -U mediakau_news mediakau_news_db > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created in backups/ directory"

# Restore database from backup
restore:
	@echo "Available backups:"
	@ls -1 backups/*.sql 2>/dev/null || echo "No backups found"
	@echo ""
	@read -p "Enter backup filename to restore: " backup; \
	if [ -f "backups/$$backup" ]; then \
		docker-compose exec -T postgres psql -U mediakau_news -d mediakau_news_db < "backups/$$backup"; \
		echo "Database restored from $$backup"; \
	else \
		echo "Backup file not found!"; \
	fi

# Remove all containers and volumes (WARNING: deletes all data)
clean:
	@echo "WARNING: This will remove all containers and volumes (including database data)!"
	@read -p "Are you sure? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose down -v; \
		echo "All containers and volumes removed."; \
	else \
		echo "Operation cancelled."; \
	fi