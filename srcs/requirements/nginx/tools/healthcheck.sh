#!/bin/bash

# Check if NGINX is responding
if curl -kfsS https://localhost/ >/dev/null; then
    exit 0
else
    exit 1
fi
