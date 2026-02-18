*This project has been created as part of the 42 curriculum by `myokono`.*

# 🐳 Inception

A Docker-based infrastructure project that sets up a multi-container application stack with NGINX, WordPress, and MariaDB. This project demonstrates system administration skills using Docker containerization and orchestration.

## 📋 Description

Inception is a system administration exercise that focuses on building a small-scale infrastructure using Docker. The project creates a fully functional WordPress website served through NGINX with TLS encryption, backed by a MariaDB database. All services run in separate Docker containers orchestrated with Docker Compose.

### Key Features
- **NGINX** web server with TLSv1.2/TLSv1.3 encryption
- **WordPress** CMS with PHP-FPM
- **MariaDB** database server
- **Docker Compose** orchestration
- **Named volumes** for data persistence
- **Docker secrets** for credential management
- **Custom Dockerfiles** for each service (no pre-built images)

### Project Goals
- Understand Docker containerization and orchestration
- Learn system administration best practices
- Implement secure credential management
- Configure networking between containers
- Manage persistent data with volumes

## 🚀 Instructions

### Prerequisites
- Linux-based operating system (virtual machine recommended)
- Docker Engine installed
- Docker Compose installed
- Sufficient disk space for volumes
- sudo/root access for setup

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd inception
```

2. **Review and update secrets** (optional)
```bash
# Edit password files in secrets/ directory
nano secrets/db_root_password.txt
nano secrets/db_password.txt
nano secrets/wp_admin_password.txt
nano secrets/wp_user_password.txt
```

3. **Build and start the infrastructure**
```bash
make
```

This command will:
- Create data directories at `/home/myokono/data/`
- Configure `/etc/hosts` to point `myokono.42.fr` to localhost
- Build all Docker images from scratch
- Start all containers

### Usage

**Access the website:**
```
https://myokono.42.fr
```

**WordPress Admin Panel:**
```
https://myokono.42.fr/wp-admin
Username: myokono
Password: (see secrets/wp_admin_password.txt)
```

### Available Commands

```bash
make        # Setup, build, and start all services
make build  # Build Docker images
make up     # Start containers
make down   # Stop and remove containers
make start  # Start existing containers
make stop   # Stop containers
make restart # Restart containers
make status # Show container status
make logs   # Show container logs (follow mode)
make clean  # Remove containers and images
make fclean # Complete cleanup including volumes and data
make re     # Rebuild everything from scratch
```

## 📚 Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

### Tutorials and Guides
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Docker Compose Tutorial](https://docs.docker.com/compose/gettingstarted/)
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

### AI Usage in This Project

AI tools were used to assist with:
- **Documentation generation**: Structuring README files and technical documentation
- **Configuration optimization**: Reviewing and optimizing NGINX, PHP-FPM, and MariaDB configurations
- **Shell script debugging**: Identifying issues in initialization scripts
- **Best practices validation**: Ensuring Docker security and performance best practices
- **Command reference**: Generating comprehensive command examples and explanations

AI was NOT used for:
- Core architecture decisions (made based on project requirements)
- Security credential generation (used standard secure password practices)
- Final testing and validation (performed manually in VM environment)

## 🏗️ Project Architecture

### Container Structure

```
┌─────────────────────────────────────────────────┐
│                   Host Machine                  │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         Docker Network (bridge)           │ │
│  │                                           │ │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐ │ │
│  │  │  NGINX   │  │WordPress │  │MariaDB │ │ │
│  │  │  :443    │→→│ :9000    │→→│ :3306  │ │ │
│  │  └──────────┘  └──────────┘  └────────┘ │ │
│  │       │              │             │     │ │
│  └───────│──────────────│─────────────│─────┘ │
│          │              │             │       │
│  ┌───────▼──────────────▼─────────────▼─────┐ │
│  │      /home/myokono/data/                 │ │
│  │      ├── wordpress/ (named volume)       │ │
│  │      └── mariadb/ (named volume)         │ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Design Choices

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|-----------------|--------|
| **Isolation** | Complete OS-level isolation | Process-level isolation |
| **Resource Usage** | Heavy (full OS per VM) | Lightweight (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Less portable | Highly portable |
| **Use Case** | Full OS needed | Application deployment |

**Why Docker for this project:**
- Faster deployment and iteration
- Lower resource consumption
- Easy orchestration with Docker Compose
- Better for microservices architecture
- Simplified dependency management

#### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|---------------|----------------------|
| **Security** | Encrypted at rest and in transit | Plain text in container |
| **Storage** | tmpfs (RAM) | Environment |
| **Visibility** | Not visible in `docker inspect` | Visible in `docker inspect` |
| **Scope** | Swarm/Compose | Any container |
| **Best For** | Passwords, keys, certificates | Non-sensitive configuration |

**Implementation:**
- Passwords: Docker secrets (files in `/run/secrets/`)
- Configuration: Environment variables (`.env` file)
- Credentials never committed to Git

#### Docker Network vs Host Network

| Aspect | Docker Network (bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Network namespace isolation | Shares host network |
| **Port Mapping** | Required | Not needed |
| **Security** | Better (isolated) | Less secure |
| **Performance** | Slight overhead | Native performance |
| **DNS** | Automatic service discovery | Manual configuration |

**Why Docker Network:**
- Better security through isolation
- Automatic DNS resolution (service names)
- Port mapping flexibility
- Standard Docker practice

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | User manages paths |
| **Portability** | More portable | Less portable |
| **Backup** | Easier with Docker tools | Manual |
| **Performance** | Optimized | Direct filesystem |
| **Permissions** | Docker handles | Can cause issues |

**Why Named Volumes:**
- Project requirement (bind mounts forbidden)
- Better data management
- Easier backup and migration
- Consistent across environments
- Docker-managed permissions

### Service Communication

1. **Client → NGINX** (Port 443, TLSv1.2/1.3)
2. **NGINX → WordPress** (FastCGI via docker network)
3. **WordPress → MariaDB** (MySQL protocol via docker network)

All inter-container communication happens through the Docker bridge network using service names as hostnames.

## 🔒 Security Considerations

- TLS encryption for all web traffic
- Secrets stored in separate files (not in environment variables)
- No credentials in Dockerfiles or Git repository
- Non-root MariaDB user for WordPress
- Security headers in NGINX configuration
- Regular security updates for base images

## 📁 Project Structure

```
inception/
├── Makefile                      # Main build automation
├── README.md                     # This file
├── USER_DOC.md                   # User documentation
├── DEV_DOC.md                    # Developer documentation
├── .gitignore                    # Git ignore rules
├── secrets/                      # Credentials (not in Git)
│   ├── credentials.txt
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                      # Environment variables
    ├── docker-compose.yml        # Container orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   ├── www.conf
        │   │   └── php.ini
        │   └── tools/
        │       └── setup-wordpress.sh
        └── nginx/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   ├── nginx.conf
            │   └── default.conf
            └── tools/
                ├── generate-ssl.sh
                └── healthcheck.sh
```

## 🎓 Learning Outcomes

- Docker container creation and management
- Docker Compose orchestration
- NGINX configuration and SSL/TLS setup
- WordPress deployment and configuration
- MariaDB database administration
- Linux system administration
- Network architecture design
- Security best practices
- Infrastructure as Code principles

## 📝 License

This project is part of the 42 school curriculum and is intended for educational purposes.

---

**Author:** myokono  
**School:** 42 Tokyo  
**Project:** Inception  
**Version:** 5.2
