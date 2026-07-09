# ── Base image ────────────────────────────────────────────────────────────────
FROM debian:bookworm

# ── Install NGINX and OpenSSL ────────────────────────────────────────────────
# nginx     — the web server / reverse proxy
# openssl   — needed to generate the self-signed TLS certificate
# gettext-base — provides envsubst, used to inject $DOMAIN_NAME into nginx.conf
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates \
        nginx \
        openssl \
        gettext-base \
    && rm -rf /var/lib/apt/lists/*

# ── Copy our NGINX configuration ──────────────────────────────────────────────
# We place it in /etc/nginx/conf.d/ — NGINX's main nginx.conf includes all
# files from that directory automatically.
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# ── Copy the SSL generation script ───────────────────────────────────────────
COPY tools/generate_ssl.sh /usr/local/bin/generate_ssl.sh
RUN chmod +x /usr/local/bin/generate_ssl.sh

# ── Generate the TLS certificate at BUILD time ────────────────────────────────
# We pass a default CN; the real domain is injected at runtime via envsubst.
# Generating at build time means startup is instant.
# ARG DOMAIN_NAME is a build-time variable (different from ENV which is runtime)
ARG DOMAIN_NAME=localhost
RUN DOMAIN_NAME=${DOMAIN_NAME} /usr/local/bin/generate_ssl.sh

# ── Expose port 443 ───────────────────────────────────────────────────────────
# The subject requires port 443 ONLY — no port 80.
EXPOSE 443

# ── Entrypoint ────────────────────────────────────────────────────────────────
# We use a shell wrapper to:
# 1. Substitute $DOMAIN_NAME into nginx.conf using envsubst
# 2. Start NGINX in the foreground (no daemon) as PID 1
#
# nginx -g 'daemon off;' — this is the canonical way to run NGINX in Docker.
# Without 'daemon off', NGINX forks a background process then the main process
# exits → Docker sees PID 1 exit → container stops immediately.
CMD ["/bin/bash", "-c", \
     "envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/default.conf \
      > /tmp/nginx_final.conf && \
      cp /tmp/nginx_final.conf /etc/nginx/conf.d/default.conf && \
      nginx -g 'daemon off;'"]