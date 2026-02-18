#!/bin/bash

# Create SSL directory
mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/myokono.42.fr.key \
    -out /etc/nginx/ssl/myokono.42.fr.crt \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=Student/CN=myokono.42.fr"

# Set proper permissions
chmod 600 /etc/nginx/ssl/myokono.42.fr.key
chmod 644 /etc/nginx/ssl/myokono.42.fr.crt

echo "SSL certificates generated successfully!"
