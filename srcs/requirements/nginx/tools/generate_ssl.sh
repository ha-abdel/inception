#!/bin/bash
# generate_ssl.sh — create a self-signed TLS certificate for HTTPS
# Called during Docker image BUILD (not at runtime)
# The certificate is baked into the image layer.

set -e

# Create the directory for SSL files
mkdir -p /etc/nginx/ssl

# Generate a 2048-bit RSA private key and a self-signed certificate
# valid for 365 days, all in one command.
#
# openssl req       — certificate request / self-sign command
# -x509             — output a self-signed certificate (not a CSR)
# -nodes            — no DES passphrase on the private key
#                     (required: NGINX can't ask for a password at startup)
# -days 365         — certificate validity period
# -newkey rsa:2048  — generate a new 2048-bit RSA key pair
# -keyout           — where to write the private key
# -out              — where to write the certificate
# -subj             — certificate subject fields (avoids interactive prompts)
#   C=MA            — Country (Morocco, adjust to yours)
#   ST=State
#   L=City
#   O=42
#   CN=${DOMAIN_NAME} — Common Name must match the domain NGINX serves

openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out    /etc/nginx/ssl/nginx.crt \
    -subj   "/C=MA/ST=Marrakech/L=BenGuerir/O=42/CN=${DOMAIN_NAME:-localhost}"