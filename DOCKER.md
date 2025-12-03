# Docker Deployment Guide for News Aggregator

This guide provides comprehensive instructions for deploying the News Aggregator application using Docker and Docker Compose.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [Configuration](#configuration)
- [Common Commands](#common-commands)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

## Prerequisites

Before you begin, ensure you have the following installed:

- Docker: Version 20.10 or higher
- Docker Compose: Version 2.0 or higher

Verify installations:
```bash
docker --version
docker-compose --version
```

## Quick Start

### 1. Environment Setup

Copy the Docker environment template and configure it:
```bash
cp .env.docker .env
```

Edit the .env file and update database credentials, application key, and API tokens.

### 2. Build and Start Containers

```bash
docker-compose build
docker-compose up -d
```

### 3. Verify Deployment

```bash
docker-compose ps
docker-compose logs -f app
```

### 4. Access the Application

The API will be available at http://localhost:80

Health check endpoint: http://localhost:80/health

## Architecture Overview

The application consists of three main services:

1. **nginx**: Web server and reverse proxy (port 80)
2. **app**: PHP-FPM application with Cron scheduler (port 9000)
3. **postgres**: PostgreSQL 15 database (port 5432)

### Persistent Volumes

- postgres_data: Database storage
- madeline_sessions: Telegram session files
- nginx_logs: Web server logs
- Host-mounted storage directories

## Configuration

### Environment Variables

Key variables in .env file:

```env
APP_NAME=Lumen
APP_ENV=production
APP_DEBUG=false
APP_URL=http://your-domain.com
APP_TIMEZONE=Asia/Jakarta

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=mediakau_news_db
DB_USERNAME=mediakau_news
DB_PASSWORD=your-password

TELEGRAM_BOT_TOKEN=your-token
TELEGRAM_CHANNEL_ID=your-channel-id
TELEGRAM_API_ID=your-api-id
TELEGRAM_API_HASH=your-hash

NGINX_PORT=80
```

## Common Commands

### Starting and Stopping

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart app
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f nginx

# Last 100 lines
docker-compose logs --tail=100 app
```

### Container Access

```bash
# Access app container shell
docker-compose exec app sh

# Access as www user
docker-compose exec -u www app sh

# Access database
docker-compose exec postgres psql -U mediakau_news -d mediakau_news_db
```

### Application Commands

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Clear cache
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear

# Install dependencies
docker-compose exec app composer install

# View scheduler logs
docker-compose exec app cat storage/logs/scheduler.log
```

## Database Management

### Running Migrations

Migrations run automatically on container start. To run manually:

```bash
docker-compose exec app php artisan migrate
```

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U mediakau_news mediakau_news_db > backup.sql

# Restore from backup
docker-compose exec -T postgres psql -U mediakau_news -d mediakau_news_db < backup.sql
```

### Accessing Database

```bash
# Using psql
docker-compose exec postgres psql -U mediakau_news -d mediakau_news_db

# Run SQL query
docker-compose exec postgres psql -U mediakau_news -d mediakau_news_db -c "SELECT COUNT(*) FROM news;"
```

## Troubleshooting

### Container Won't Start

Check logs and verify configuration:
```bash
docker-compose logs app
docker-compose config
```

### Database Connection Issues

Verify PostgreSQL is running and healthy:
```bash
docker-compose ps postgres
docker-compose exec postgres pg_isready -U mediakau_news
```

### Permission Issues

Fix storage permissions:
```bash
docker-compose exec app chown -R www:www /var/www/html/storage
docker-compose exec app chmod -R 775 /var/www/html/storage
```

### Scheduler Not Running

Check cron logs and verify it is running:
```bash
docker-compose exec app cat /var/www/html/storage/logs/cron.log
docker-compose exec app ps aux | grep cron
docker-compose exec app php artisan schedule:run
```

### High Memory Usage

Check container stats and restart if needed:
```bash
docker stats
docker-compose restart app
```

## Production Deployment

### Security Considerations

1. Never commit .env file to version control
2. Use strong passwords for database
3. Set APP_DEBUG=false
4. Set APP_ENV=production
5. Enable SSL/HTTPS for public access

### Performance Optimization

The Dockerfile includes optimizations:
- OPcache enabled
- Memory limit: 512M
- Gzip compression in Nginx
- Static file caching

### Scaling

To scale the application horizontally:
```bash
docker-compose up -d --scale app=3
```

Note: Requires load balancer configuration

### Monitoring

Check health status:
```bash
docker-compose ps
curl http://localhost/health
```

Monitor resources:
```bash
docker stats
```

Database monitoring:
```bash
docker-compose exec postgres psql -U mediakau_news -d mediakau_news_db -c "SELECT count(*) FROM pg_stat_activity;"
```

## Updating the Application

Pull latest changes and restart:
```bash
git pull origin main
docker-compose build
docker-compose up -d
docker-compose exec app php artisan migrate
```

## Additional Resources

- Docker Documentation: https://docs.docker.com/
- Docker Compose Documentation: https://docs.docker.com/compose/
- Lumen Documentation: https://lumen.laravel.com/docs
- PostgreSQL Documentation: https://www.postgresql.org/docs/
