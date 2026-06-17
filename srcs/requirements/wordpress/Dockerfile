# ── Base image ────────────────────────────────────────────────────────────────
FROM debian:bookworm

# ── Install PHP-FPM and WordPress dependencies ───────────────────────────────
# php-fpm8.2    — PHP FastCGI Process Manager (runs PHP code)
# php-mysql     — PHP extension to talk to MySQL/MariaDB
# php-curl      — for WordPress HTTP API calls (plugin updates, etc.)
# php-dom       — XML/HTML parsing (used by many WP plugins)
# php-exif      — reads image metadata (WP media library)
# php-fileinfo  — MIME type detection (file uploads)
# php-gd        — image resizing (thumbnails)
# php-imagick   — higher-quality image processing
# php-mbstring  — multi-byte string handling (internationalization)
# php-openssl   — HTTPS calls from WordPress
# php-ping      — (via default-mysql-client) we need mysqladmin for health check
# php-xml       — XML parsing (RSS feeds, sitemaps)
# php-zip       — plugin/theme installation
# default-mysql-client — provides mysqladmin for the readiness check in setup.sh
# curl, wget    — used by WP-CLI to download WordPress
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-dom \
        php8.2-exif \
        php8.2-fileinfo \
        php8.2-gd \
        php8.2-imagick \
        php8.2-mbstring \
        php8.2-openssl \
        php8.2-xml \
        php8.2-zip \
        default-mysql-client \
        curl \
        wget \
    && rm -rf /var/lib/apt/lists/*

# ── Install WP-CLI ────────────────────────────────────────────────────────────
# WP-CLI is the command-line interface for WordPress.
# We use it in setup.sh to download WP, create wp-config.php,
# run the installer, and create users — all non-interactively.
# We download the phar (PHP archive), make it executable, move to PATH.
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# ── PHP-FPM configuration ─────────────────────────────────────────────────────
# Replace the default www.conf pool config with ours.
# The default path depends on the PHP version installed.
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# ── WordPress document root ───────────────────────────────────────────────────
# Create the directory where WP files will live.
# This is the mount point for the wordpress_files volume.
# www-data ownership lets PHP-FPM read/write files without privilege issues.
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

# ── PHP-FPM run directory ─────────────────────────────────────────────────────
# php-fpm needs /run/php to write its PID file
RUN mkdir -p /run/php

# ── Copy entrypoint script ────────────────────────────────────────────────────
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# ── Expose PHP-FPM port ───────────────────────────────────────────────────────
# PHP-FPM listens on 9000 for FastCGI connections from NGINX.
# Only reachable inside the docker network — never exposed to the host.
EXPOSE 9000

CMD ["setup.sh"]