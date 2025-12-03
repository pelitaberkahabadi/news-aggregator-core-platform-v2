#!/bin/sh
set -e

# Health check script for the application container
# This script checks if PHP-FPM, PostgreSQL connection, and Cron are working

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check PHP-FPM status
check_php_fpm() {
    if pgrep -x php-fpm > /dev/null; then
        echo "${GREEN}✓${NC} PHP-FPM is running"
        return 0
    else
        echo "${RED}✗${NC} PHP-FPM is not running"
        return 1
    fi
}

# Function to check PostgreSQL connection
check_database() {
    if PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_DATABASE" -c '\q' 2>/dev/null; then
        echo "${GREEN}✓${NC} Database connection successful"
        return 0
    else
        echo "${RED}✗${NC} Database connection failed"
        return 1
    fi
}

# Function to check Cron daemon
check_cron() {
    if pgrep -x crond > /dev/null; then
        echo "${GREEN}✓${NC} Cron daemon is running"
        return 0
    else
        echo "${RED}✗${NC} Cron daemon is not running"
        return 1
    fi
}

# Function to check supervisor
check_supervisor() {
    if pgrep -x supervisord > /dev/null; then
        echo "${GREEN}✓${NC} Supervisor is running"
        return 0
    else
        echo "${RED}✗${NC} Supervisor is not running"
        return 1
    fi
}

# Main health check
main() {
    echo "Running health checks..."
    
    FAILED=0
    
    check_php_fpm || FAILED=$((FAILED + 1))
    check_database || FAILED=$((FAILED + 1))
    check_cron || FAILED=$((FAILED + 1))
    check_supervisor || FAILED=$((FAILED + 1))
    
    if [ $FAILED -eq 0 ]; then
        echo "${GREEN}All health checks passed!${NC}"
        exit 0
    else
        echo "${RED}$FAILED health check(s) failed!${NC}"
        exit 1
    fi
}

# Run main function
main