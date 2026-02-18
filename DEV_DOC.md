# 🔧 Developer Documentation

## Technical Overview

This documentation is for developers who want to understand, modify, or extend the Inception infrastructure.

## 🏗️ Architecture

### Service Overview

```
┌─────────────────────────────────────────────────────┐
│                    Docker Host                      │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │       inception-network (bridge)             │  │
│  │                                              │  │
│  │  ┌─────────────────────────────────────┐    │  │
│  │  │         NGINX Container             │    │  │
│  │  │  - Port: 443 (HTTPS)                │    │  │
│  │  │  - TLS 1.2/1.3                      │    │  │
│  │  │  - Reverse proxy to WordPress       │    │  │
│  │  │  - Serves static files              │    │  │
│  │  └──────────┬──────────────────────────┘    │  │
│  │             │ FastCGI (9000)                │  │
│  │  ┌──────────▼──────────────────────────┐    │  │
│  │  │      WordPress Container            │    │  │
│  │  │  - PHP 8.2 + PHP-FPM                │    │  │
│  │  │  - WordPress CMS                    │    │  │
│  │  │  - WP-CLI                           │    │  │
│  │  └──────────┬──────────────────────────┘    │  │
│  │             │ MySQL (3306)                  │  │
│  │  ┌──────────▼──────────────────────────┐    │  │
│  │  │       MariaDB Container             │    │  │
│  │  │  - MariaDB 10.x                     │    │  │
│  │  │  - WordPress database               │    │  │
│  │  │  - User: wpuser                     │    │  │
│  │  └─────────────────────────────────────┘    │  │
│  │                                              │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │          Named Volumes                       │  │
│  │  wordpress-data → /home/myokono/data/wordpress  │
│  │  mariadb-data   → /home/myokono/data/mariadb    │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │          Docker Secrets (tmpfs)              │  │
│  │  - db_root_password                          │  │
│  │  - db_password                               │  │
│  │  - wp_admin_password                         │  │
│  │  - wp_user_password                          │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 🚀 Setting Up Development Environment

### Prerequisites

Install required software:

```bash
# Update package list
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Log out and back in for group changes to take effect
```

### Initial Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd inception
```

2. **Create data directories**
```bash
sudo mkdir -p /home/myokono/data/wordpress
sudo mkdir -p /home/myokono/data/mariadb
sudo chown -R $USER:$USER /home/myokono/data
```

3. **Configure domain name**
```bash
# Add domain to /etc/hosts
echo "127.0.0.1 myokono.42.fr" | sudo tee -a /etc/hosts
```

4. **Review secrets**
```bash
# Check all credential files exist
ls -la secrets/
```

5. **Set proper permissions**
```bash
chmod 600 secrets/*.txt
```

## 🔨 Building the Project

### Build Process

The build process is managed through the Makefile:

```bash
# Complete setup and build
make

# Individual steps:
make setup    # Create directories and configure host
make build    # Build Docker images
make up       # Start containers
```

### Building Individual Services

```bash
# Build specific service
docker-compose -f srcs/docker-compose.yml build mariadb
docker-compose -f srcs/docker-compose.yml build wordpress
docker-compose -f srcs/docker-compose.yml build nginx

# Build with no cache (force rebuild)
docker-compose -f srcs/docker-compose.yml build --no-cache
```

### Build Output

Expected build time: 5-10 minutes (depending on network speed)

Each service will:
1. Pull base image (Debian Bookworm)
2. Install required packages
3. Copy configuration files
4. Set up scripts and permissions
5. Create necessary directories

## 🐳 Docker Compose Configuration

### Service Dependencies

```yaml
mariadb:
  # No dependencies, starts first
  healthcheck: MySQL ping

wordpress:
  depends_on:
    mariadb:
      condition: service_healthy
  healthcheck: PHP-FPM test

nginx:
  depends_on:
    wordpress:
      condition: service_healthy
  healthcheck: HTTPS request
```

### Environment Variables

Defined in `srcs/.env`:

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN_NAME` | Website domain | myokono.42.fr |
| `MYSQL_DATABASE` | Database name | wordpress |
| `MYSQL_USER` | DB user | wpuser |
| `DB_HOST` | Database host | mariadb:3306 |
| `WP_ADMIN_USER` | WordPress admin | myokono |

### Secrets Management

Secrets are mounted as files in `/run/secrets/`:

```bash
# In containers:
/run/secrets/db_root_password
/run/secrets/db_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password

# Read in scripts:
DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
```

### Volume Configuration

Named volumes with bind mount driver options:

```yaml
volumes:
  wordpress-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/myokono/data/wordpress
```

This creates a named volume that binds to a specific host directory.

## 📦 Service Details

### MariaDB Service

**Dockerfile location:** `srcs/requirements/mariadb/Dockerfile`

**Base image:** `debian:bookworm`

**Packages installed:**
- mariadb-server
- mariadb-client

**Configuration:**
- `conf/50-server.cnf` - Server configuration
- `tools/init-db.sh` - Database initialization script

**Initialization process:**
1. Check if database exists
2. If not, run `mysql_install_db`
3. Bootstrap MySQL with:
   - Set root password
   - Create WordPress database
   - Create WordPress user
   - Set permissions
   - Remove test database
   - Remove anonymous users

**Exposed port:** 3306 (internal only)

### WordPress Service

**Dockerfile location:** `srcs/requirements/wordpress/Dockerfile`

**Base image:** `debian:bookworm`

**Packages installed:**
- php8.2-fpm
- php8.2-mysql
- php8.2-curl
- php8.2-gd
- php8.2-intl
- php8.2-mbstring
- php8.2-soap
- php8.2-xml
- php8.2-xmlrpc
- php8.2-zip
- php8.2-redis
- curl
- mariadb-client
- WP-CLI

**Configuration:**
- `conf/www.conf` - PHP-FPM pool configuration
- `conf/php.ini` - PHP settings
- `tools/setup-wordpress.sh` - WordPress setup script

**Setup process:**
1. Wait for MariaDB to be ready
2. Download WordPress core with WP-CLI
3. Create `wp-config.php`
4. Install WordPress
5. Create admin user
6. Create editor user
7. Configure permalink structure
8. Install plugins (redis-cache)

**Exposed port:** 9000 (FastCGI, internal only)

### NGINX Service

**Dockerfile location:** `srcs/requirements/nginx/Dockerfile`

**Base image:** `debian:bookworm`

**Packages installed:**
- nginx
- openssl

**Configuration:**
- `conf/nginx.conf` - Main NGINX configuration
- `conf/default.conf` - Virtual host configuration
- `tools/generate-ssl.sh` - SSL certificate generation
- `tools/healthcheck.sh` - Health check script

**Features:**
- TLS 1.2 and 1.3 only
- Self-signed SSL certificate
- FastCGI proxy to WordPress
- Static file caching
- Security headers
- WordPress permalink support

**Exposed port:** 443 (HTTPS)

## 🛠️ Development Commands

### Container Management

```bash
# Start containers
docker-compose -f srcs/docker-compose.yml up -d

# Stop containers
docker-compose -f srcs/docker-compose.yml down

# Restart specific service
docker-compose -f srcs/docker-compose.yml restart nginx

# View logs
docker-compose -f srcs/docker-compose.yml logs -f

# Execute command in container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect inception_wordpress-data

# Check volume contents
sudo ls -la /home/myokono/data/wordpress/
sudo ls -la /home/myokono/data/mariadb/

# Backup volume
sudo tar -czf backup.tar.gz /home/myokono/data/
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception_inception-network

# Test connectivity
docker exec wordpress ping mariadb
docker exec nginx ping wordpress
```

### Image Management

```bash
# List images
docker images

# Remove specific image
docker rmi mariadb:inception

# Remove all project images
docker-compose -f srcs/docker-compose.yml down --rmi all

# Prune unused images
docker image prune -a
```

## 🔍 Debugging

### Check Service Health

```bash
# Check all healthchecks
docker ps --format "table {{.Names}}\t{{.Status}}"

# Manual healthcheck
docker exec mariadb mysqladmin ping -h localhost
docker exec wordpress php-fpm8.2 -t
docker exec nginx nginx -t
```

### View Logs

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs

# Specific service
docker logs mariadb
docker logs wordpress
docker logs nginx

# Follow logs in real-time
docker logs -f nginx

# Last 50 lines
docker logs --tail 50 mariadb
```

### Inspect Container State

```bash
# Full container inspection
docker inspect mariadb

# Check environment variables
docker exec mariadb env

# Check mounted volumes
docker exec wordpress mount | grep /var/www/html

# Check network configuration
docker exec wordpress cat /etc/hosts
```

### Database Debugging

```bash
# Connect to MariaDB
docker exec -it mariadb mysql -u root -p
# Enter root password from secrets/db_root_password.txt

# Check databases
SHOW DATABASES;

# Check WordPress database
USE wordpress;
SHOW TABLES;

# Check users
SELECT User, Host FROM mysql.user;

# Check WordPress user permissions
SHOW GRANTS FOR 'wpuser'@'%';
```

### WordPress Debugging

```bash
# WP-CLI commands
docker exec wordpress wp --info --allow-root
docker exec wordpress wp plugin list --allow-root
docker exec wordpress wp theme list --allow-root
docker exec wordpress wp user list --allow-root

# Check database connection
docker exec wordpress wp db check --allow-root

# WordPress configuration
docker exec wordpress wp config list --allow-root
```

### NGINX Debugging

```bash
# Test configuration
docker exec nginx nginx -t

# Reload configuration
docker exec nginx nginx -s reload

# Check SSL certificate
docker exec nginx openssl x509 -in /etc/nginx/ssl/myokono.42.fr.crt -text -noout

# Test HTTPS locally
docker exec nginx curl -k https://localhost/
```

## 📊 Data Persistence

### Volume Locations

```
Host Machine:
/home/myokono/data/
├── wordpress/
│   ├── wp-admin/
│   ├── wp-content/
│   ├── wp-includes/
│   └── wp-config.php
└── mariadb/
    ├── mysql/
    ├── wordpress/
    └── (other system databases)
```

### Backup Strategy

```bash
#!/bin/bash
# backup.sh - Backup script

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup WordPress files
sudo tar -czf $BACKUP_DIR/wordpress_$DATE.tar.gz /home/myokono/data/wordpress/

# Backup MariaDB
docker exec mariadb mysqldump -u root -p$(cat secrets/db_root_password.txt) --all-databases > $BACKUP_DIR/mariadb_$DATE.sql

echo "Backup completed: $DATE"
```

### Restore Strategy

```bash
#!/bin/bash
# restore.sh - Restore script

# Stop containers
make down

# Restore WordPress files
sudo tar -xzf /backups/wordpress_YYYYMMDD_HHMMSS.tar.gz -C /

# Start MariaDB only
docker-compose -f srcs/docker-compose.yml up -d mariadb

# Wait for MariaDB
sleep 10

# Restore database
cat /backups/mariadb_YYYYMMDD_HHMMSS.sql | docker exec -i mariadb mysql -u root -p$(cat secrets/db_root_password.txt)

# Start all services
make up
```

## 🔧 Customization

### Changing Domain Name

1. Update `srcs/.env`:
```bash
DOMAIN_NAME=newdomain.42.fr
```

2. Update `/etc/hosts`:
```bash
127.0.0.1 newdomain.42.fr
```

3. Update NGINX config `srcs/requirements/nginx/conf/default.conf`:
```nginx
server_name newdomain.42.fr;
```

4. Update SSL generation script `srcs/requirements/nginx/tools/generate-ssl.sh`:
```bash
-subj "/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=Student/CN=newdomain.42.fr"
```

5. Rebuild:
```bash
make fclean
make
```

### Adding PHP Extensions

Edit `srcs/requirements/wordpress/Dockerfile`:

```dockerfile
RUN apt-get install -y \
    php8.2-imagick \
    php8.2-memcached \
    # ... other extensions
```

### Adjusting PHP-FPM Settings

Edit `srcs/requirements/wordpress/conf/www.conf`:

```ini
pm.max_children = 100        # Increase for more traffic
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
```

### Database Performance Tuning

Edit `srcs/requirements/mariadb/conf/50-server.cnf`:

```ini
innodb_buffer_pool_size = 512M    # Increase for better performance
max_connections = 200              # More concurrent connections
```

## 🧪 Testing

### Automated Tests

```bash
#!/bin/bash
# test.sh - Simple test script

echo "Testing NGINX..."
curl -k https://myokono.42.fr/ | grep -q "WordPress" && echo "✓ NGINX OK" || echo "✗ NGINX FAIL"

echo "Testing WordPress..."
docker exec wordpress wp --info --allow-root &>/dev/null && echo "✓ WordPress OK" || echo "✗ WordPress FAIL"

echo "Testing MariaDB..."
docker exec mariadb mysqladmin ping -h localhost &>/dev/null && echo "✓ MariaDB OK" || echo "✗ MariaDB FAIL"

echo "Testing connectivity..."
docker exec wordpress ping -c 1 mariadb &>/dev/null && echo "✓ Network OK" || echo "✗ Network FAIL"
```

### Manual Testing Checklist

- [ ] All containers start successfully
- [ ] `https://myokono.42.fr` loads WordPress
- [ ] Can log in to WordPress admin
- [ ] Can create and publish a post
- [ ] Static files (images) load correctly
- [ ] Database connection is stable
- [ ] SSL certificate is valid (self-signed)
- [ ] Containers restart after host reboot
- [ ] Data persists after container restart

## 📚 Additional Resources

### Documentation
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)

### Troubleshooting Resources
- [Docker Logs](https://docs.docker.com/engine/reference/commandline/logs/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)

---

**For user instructions, see USER_DOC.md**
