FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    curl \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/homer && \
    curl -fsSL \
        https://github.com/bastienwirtz/homer/releases/download/v23.10.1/homer.zip \
        -o /tmp/homer.zip && \
    unzip /tmp/homer.zip -d /var/www/homer && \
    rm /tmp/homer.zip

COPY site/config.yml /var/www/homer/assets/config.yml

COPY /site/config.conf /etc/nginx/sites-enabled/default 



EXPOSE 8085

CMD ["nginx", "-g", "daemon off;"]