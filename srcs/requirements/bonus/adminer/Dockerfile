FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-cli \
    php-mysqli \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN mkdir -p /var/www/html && \
    wget -O /var/www/html/index.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080"]