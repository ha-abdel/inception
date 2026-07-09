#!/bin/bash

set -e

mkdir -p /etc/nginx/ssl


openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out    /etc/nginx/ssl/nginx.crt \
    -subj   "/C=MA/ST=Marrakech/L=BenGuerir/O=42/CN=${DOMAIN_NAME:-localhost}"