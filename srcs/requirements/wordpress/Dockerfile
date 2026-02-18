FROM debian:bookworm

# Install WordPress dependencies
RUN apt-get update && \
    apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-soap \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-zip \
    php8.2-redis \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY conf/php.ini /etc/php/8.2/fpm/php.ini

# Copy WordPress setup script
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh
RUN chmod +x /usr/local/bin/setup-wordpress.sh

# Create PHP-FPM run directory
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

# Create WordPress directory
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Set working directory
WORKDIR /var/www/html

# Run setup script
ENTRYPOINT ["/usr/local/bin/setup-wordpress.sh"]

# Start PHP-FPM
CMD ["php-fpm8.2", "-F"]
