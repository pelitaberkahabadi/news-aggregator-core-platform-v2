#!/bin/bash
set -e

echo "Starting News Aggregator Application..."

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    
    until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_DATABASE" -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done
    
    echo "PostgreSQL is ready!"
}

# Function to set correct permissions
set_permissions() {
    echo "Setting correct permissions..."
    
    # Ensure storage directories exist
    mkdir -p /var/www/html/storage/framework/cache/data
    mkdir -p /var/www/html/storage/framework/sessions
    mkdir -p /var/www/html/storage/framework/views
    mkdir -p /var/www/html/storage/logs
    mkdir -p /var/www/html/storage/app/madeline
    mkdir -p /var/www/html/bootstrap/cache
    
    # Set ownership
    chown -R www:www /var/www/html/storage
    chown -R www:www /var/www/html/bootstrap/cache
    
    # Set permissions
    chmod -R 775 /var/www/html/storage
    chmod -R 775 /var/www/html/bootstrap/cache
    
    echo "Permissions set successfully!"
}

# Function to run database migrations
run_migrations() {
    echo "Running database migrations..."
    
    # Run migrations as www user
    su -s /bin/sh -c "cd /var/www/html && php artisan migrate --force" www
    
    echo "Migrations completed!"
}

# Function to cache configuration
cache_config() {
    echo "Caching configuration..."
    
    # Clear and cache config as www user
    su -s /bin/sh -c "cd /var/www/html && php artisan config:clear" www
    su -s /bin/sh -c "cd /var/www/html && php artisan cache:clear" www
    
    echo "Configuration cached!"
}

# Function to create log directory for supervisor
setup_supervisor() {
    echo "Setting up supervisor..."
    mkdir -p /var/log/supervisor
    echo "Supervisor setup complete!"
}

# Main execution
main() {
    # Wait for PostgreSQL
    wait_for_postgres
    
    # Set permissions
    set_permissions
    
    # Run migrations
    run_migrations
    
    # Cache configuration
    cache_config
    
    # Setup supervisor
    setup_supervisor
    
    echo "Initialization complete! Starting application services..."
    
    # Execute the command passed to docker run
    exec "$@"
}

# Run main function
main "$@"