#!/bin/bash
set -e

echo "WordPress Setup Script"

# Read secrets
DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
WP_ADMIN_PASSWORD=$(cat "$WP_ADMIN_PASSWORD_FILE")
WP_USER_PASSWORD=$(cat "$WP_USER_PASSWORD_FILE")

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h"${DB_HOST%:*}" -P"${DB_HOST#*:}" -u"${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
echo "MariaDB is ready!"

# Change to WordPress directory
cd /var/www/html

# Download WordPress if not exists
if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."
    
    # Download WordPress core
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    # Create additional user
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    
    # Configure WordPress settings
    wp option update permalink_structure '/%postname%/' --allow-root
    wp option update blogdescription 'Docker-based WordPress installation' --allow-root
    
    # Install and activate useful plugins
    wp plugin install redis-cache --activate --allow-root || true
    
    echo "WordPress installed successfully!"
else
    echo "WordPress is already installed."
fi

# Fix permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec "$@"
