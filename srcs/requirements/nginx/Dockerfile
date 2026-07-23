FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        gettext-base \
    && rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/conf.d/default.conf


RUN rm -f /etc/nginx/sites-enabled/default

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]