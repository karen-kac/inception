# 📖 User Documentation

## Welcome to Inception

This documentation explains how to use the Inception infrastructure as an end user or administrator.

## 🎯 What Services Are Provided?

### WordPress Website
A fully functional WordPress content management system where you can:
- Create and publish blog posts
- Manage pages and media
- Customize themes and plugins
- Manage users and permissions

### Secure HTTPS Access
All traffic is encrypted using TLS 1.2/1.3 protocol for secure communication.

### Database Backend
A MariaDB database that stores all WordPress content and configuration.

## 🚀 Getting Started

### 1. Starting the Project

To start all services:
```bash
cd /path/to/inception
make
```

This will:
- Set up data directories
- Configure domain name
- Build Docker images
- Start all containers

**Expected output:**
```
Setting up data directories...
✓ Data directories created
Configuring /etc/hosts...
✓ Domain configured
Building Docker images...
✓ Images built successfully
Starting containers...
✓ Containers started
WordPress is available at: https://myokono.42.fr
```

### 2. Accessing the Website

Open your web browser and navigate to:
```
https://myokono.42.fr
```

**Note:** You will see a security warning because the SSL certificate is self-signed. This is normal for development. Click "Advanced" → "Proceed to myokono.42.fr" to continue.

### 3. Accessing the Admin Panel

To manage your WordPress site:

1. Go to: `https://myokono.42.fr/wp-admin`
2. Log in with admin credentials (see credentials section below)
3. Start creating content!

### 4. Stopping the Project

To stop all services:
```bash
make stop
```

To stop and remove containers:
```bash
make down
```

## 🔑 Managing Credentials

### Location of Credentials

All credentials are stored in the `secrets/` directory:

```
secrets/
├── credentials.txt           # Master credentials file
├── db_root_password.txt      # MariaDB root password
├── db_password.txt           # WordPress database user password
├── wp_admin_password.txt     # WordPress admin password
└── wp_user_password.txt      # WordPress editor password
```

### Default Users

#### WordPress Admin
- **Username:** myokono
- **Password:** See `secrets/wp_admin_password.txt`
- **Email:** myokono@student.42.fr
- **Role:** Administrator (full access)

#### WordPress Editor
- **Username:** wpeditor
- **Password:** See `secrets/wp_user_password.txt`
- **Email:** editor@student.42.fr
- **Role:** Editor (can create/publish posts)

#### Database Access
- **Root User:** root
- **Root Password:** See `secrets/db_root_password.txt`
- **WordPress User:** wpuser
- **WordPress Password:** See `secrets/db_password.txt`

### Viewing Credentials

To view all credentials:
```bash
cat secrets/credentials.txt
```

To view a specific password:
```bash
cat secrets/wp_admin_password.txt
```

### Changing Passwords

⚠️ **Important:** Change default passwords in production!

1. **Edit the secret files:**
```bash
nano secrets/wp_admin_password.txt
# Change the password
# Save and exit (Ctrl+X, Y, Enter)
```

2. **Rebuild and restart:**
```bash
make fclean
make
```

## ✅ Checking Service Status

### View Running Containers

```bash
make status
```

**Expected output:**
```
Container status:
NAME       IMAGE                 STATUS         PORTS
nginx      nginx:inception       Up 2 minutes   0.0.0.0:443->443/tcp
wordpress  wordpress:inception   Up 2 minutes   9000/tcp
mariadb    mariadb:inception     Up 2 minutes   3306/tcp
```

All services should show `Up` status.

### View Container Logs

To see what's happening inside containers:

```bash
# All containers
make logs

# Specific container
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check Individual Services

#### 1. Check NGINX
```bash
docker exec nginx nginx -t
```
Should output: `configuration file /etc/nginx/nginx.conf test is successful`

#### 2. Check WordPress
```bash
docker exec wordpress wp --info --allow-root
```
Should display PHP and WordPress version information

#### 3. Check MariaDB
```bash
docker exec mariadb mysqladmin ping -h localhost
```
Should output: `mysqld is alive`

### Verify Network Connectivity

```bash
# Check if containers can communicate
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress
```

Both should successfully ping each other.

## 🔧 Common Tasks

### Restarting Services

```bash
# Restart all services
make restart

# Restart specific service
docker restart nginx
docker restart wordpress
docker restart mariadb
```

### Viewing Website Logs

NGINX access logs:
```bash
docker exec nginx tail -f /var/log/nginx/myokono.42.fr.access.log
```

NGINX error logs:
```bash
docker exec nginx tail -f /var/log/nginx/myokono.42.fr.error.log
```

### Backing Up Data

Data is stored in `/home/myokono/data/`:

```bash
# Backup WordPress files
sudo tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/myokono/data/wordpress/

# Backup MariaDB database
sudo tar -czf mariadb-backup-$(date +%Y%m%d).tar.gz /home/myokono/data/mariadb/
```

### Accessing Database

```bash
# Connect to database
docker exec -it mariadb mysql -u wpuser -p wordpress

# Enter password from secrets/db_password.txt
# Now you can run SQL queries
```

## 🐛 Troubleshooting

### Website Not Loading

1. **Check if containers are running:**
```bash
make status
```

2. **Check domain configuration:**
```bash
cat /etc/hosts | grep myokono
```
Should show: `127.0.0.1 myokono.42.fr`

3. **Check NGINX logs:**
```bash
docker logs nginx
```

### Database Connection Errors

1. **Check MariaDB is running:**
```bash
docker exec mariadb mysqladmin ping -h localhost
```

2. **Check WordPress can reach database:**
```bash
docker exec wordpress wp db check --allow-root
```

3. **Verify database credentials in WordPress:**
```bash
docker exec wordpress wp config get --allow-root
```

### SSL Certificate Warnings

The self-signed certificate will always show a warning in browsers. This is expected behavior. To avoid the warning:

1. Click "Advanced" in your browser
2. Click "Proceed to myokono.42.fr (unsafe)"
3. Or add the certificate to your browser's trusted certificates

### Containers Keep Restarting

Check container logs for errors:
```bash
docker logs mariadb --tail 50
docker logs wordpress --tail 50
docker logs nginx --tail 50
```

### Port Already in Use

If port 443 is already in use:
```bash
# Check what's using port 443
sudo lsof -i :443

# Stop the conflicting service
sudo systemctl stop <service-name>
```

## 📊 Monitoring

### Disk Usage

Check volume sizes:
```bash
# WordPress volume
du -sh /home/myokono/data/wordpress/

# MariaDB volume
du -sh /home/myokono/data/mariadb/

# Total usage
du -sh /home/myokono/data/
```

### Container Resource Usage

```bash
docker stats
```

Shows real-time CPU, memory, and network usage for all containers.

## 🛡️ Security Best Practices

1. **Change default passwords** immediately after first setup
2. **Keep WordPress updated** via the admin panel
3. **Use strong passwords** (minimum 12 characters, mixed case, numbers, symbols)
4. **Regularly backup data** to external storage
5. **Monitor logs** for suspicious activity
6. **Update base images** regularly and rebuild containers

## 📞 Support

If you encounter issues:

1. Check the logs: `make logs`
2. Verify all services are running: `make status`
3. Restart services: `make restart`
4. Clean rebuild: `make fclean && make`
5. Consult the DEV_DOC.md for technical details

## 🔄 Maintenance Schedule

### Daily
- Check service status
- Monitor disk usage

### Weekly
- Review logs for errors
- Backup data

### Monthly
- Update WordPress core and plugins
- Rebuild containers with latest base images
- Review and rotate passwords

---

**For technical details and development information, see DEV_DOC.md**
