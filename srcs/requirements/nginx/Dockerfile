FROM debian:bookworm

# Install NGINX and OpenSSL
RUN apt-get update && \
    apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Copy SSL certificate generation script
COPY tools/generate-ssl.sh /usr/local/bin/generate-ssl.sh
RUN chmod +x /usr/local/bin/generate-ssl.sh

# Generate SSL certificates
RUN /usr/local/bin/generate-ssl.sh

# Create NGINX run directory
RUN mkdir -p /run/nginx

# Expose HTTPS port
EXPOSE 443

# Health check script
COPY tools/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
