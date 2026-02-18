#!/bin/bash
set -e

echo "MariaDB Initialization Script"

# Read secrets
DB_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    
    # Initialize database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start temporary MySQL server
    mysqld --user=mysql --bootstrap --verbose=0 << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create user and grant privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Secure installation
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

FLUSH PRIVILEGES;
EOF

    echo "MariaDB database initialized successfully!"
else
    echo "MariaDB database already initialized."
fi

echo "Starting MariaDB server..."
exec "$@"
