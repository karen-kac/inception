#!/bin/bash

# Check if NGINX is responding
if wget --no-verbose --tries=1 --spider --no-check-certificate https://localhost/ 2>&1 | grep -q '200 OK'; then
    exit 0
else
    exit 1
fi
