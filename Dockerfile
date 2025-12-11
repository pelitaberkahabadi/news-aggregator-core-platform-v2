# Multi-stage build for optimized production image
FROM php:8.1-fpm-alpine AS base

# Install system dependencies and PHP extensions
RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    g++ \
    make \
    && apk add --no-cache \
    postgresql-dev \
    libxml2-dev \
    curl-dev \
    libzip-dev \
    gmp-dev \
    oniguruma-dev \
    bash \
    supervisor \
    dcron \
    libcap \
    && docker-php-ext-install \
    pdo_pgsql \
    pgsql \
    mbstring \
    xml \
    bcmath \
    gmp \
    zip \
    opcache \
    && apk del .build-deps

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "memory_limit = 512M" >> "$PHP_INI_DIR/conf.d/memory.ini" \
    && echo "max_execution_time = 300" >> "$PHP_INI_DIR/conf.d/execution.ini" \
    && echo "upload_max_filesize = 50M" >> "$PHP_INI_DIR/conf.d/uploads.ini" \
    && echo "post_max_size = 50M" >> "$PHP_INI_DIR/conf.d/uploads.ini"

# Configure OPcache for production
RUN echo "opcache.enable=1" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.memory_consumption=256" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.interned_strings_buffer=16" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.max_accelerated_files=10000" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.validate_timestamps=0" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.save_comments=1" >> "$PHP_INI_DIR/conf.d/opcache.ini" \
    && echo "opcache.fast_shutdown=1" >> "$PHP_INI_DIR/conf.d/opcache.ini"

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Create application user and set permissions
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www && \
    # Create the root folder if it doesn't exist
    mkdir -p /var/www/html && \
    chown -R www:www /var/www/html && \
    # Create ALL necessary directories, including bootstrap/cache
    mkdir -p /var/www/html/storage/framework/cache/data \
             /var/www/html/storage/framework/sessions \
             /var/www/html/storage/framework/views \
             /var/www/html/storage/logs \
             /var/www/html/storage/app/madeline \
             /var/www/html/bootstrap/cache && \
    # Now that they definitely exist, permissions will work
    chown -R www:www /var/www/html/storage \
                   /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage \
                 /var/www/html/bootstrap/cache

# Copy Docker configuration files
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/cron/laravel-cron /etc/crontabs/www
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

# Set proper permissions for cron and scripts
RUN chmod 0644 /etc/crontabs/www && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/healthcheck.sh && \
    chown www:www /etc/crontabs/www

# Configure PHP-FPM to run as www user
RUN sed -i 's/user = nobody/user = www/g' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/group = nobody/group = www/g' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /usr/local/etc/php-fpm.d/www.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Expose PHP-FPM port
EXPOSE 9000

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]