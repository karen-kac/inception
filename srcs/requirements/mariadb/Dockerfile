FROM debian:bookworm

# Install MariaDB Server
RUN apt-get update && \
    apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh

# Create run directory for mysqld
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld

# Expose MySQL port
EXPOSE 3306

# Set working directory
WORKDIR /var/lib/mysql

# Run initialization script
ENTRYPOINT ["/usr/local/bin/init-db.sh"]

# Start MariaDB server
CMD ["mysqld"]
