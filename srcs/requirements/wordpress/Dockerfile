# ── Base image ────────────────────────────────────────────────────────────────
FROM debian:bookworm


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-dom \
        php8.2-exif \
        php8.2-fileinfo \
        php8.2-gd \
        php8.2-imagick \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        default-mysql-client \
        curl \
        wget \
    && rm -rf /var/lib/apt/lists/*


RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp


COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf


RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html


RUN mkdir -p /run/php

# ── Copy entrypoint script ────────────────────────────────────────────────────
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

CMD ["setup.sh"]