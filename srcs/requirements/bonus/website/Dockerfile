FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*


COPY site/index.html /var/www/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]