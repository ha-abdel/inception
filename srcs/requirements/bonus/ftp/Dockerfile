FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vsftpd \
        gettext-base \
    && rm -rf /var/lib/apt/lists/*

# vsftpd expects it even when there is no SSL.
RUN mkdir -p /etc/vsftpd/ssl && \
    mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Port 21: FTP control connection (login, commands)
# Ports 21100-21110: passive data connections (file transfers)
EXPOSE 21 21100-21110

ENTRYPOINT ["entrypoint.sh"]
