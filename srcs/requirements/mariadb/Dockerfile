FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
    && rm -rf /var/lib/apt/lists/*

#create directory that contains socket file
RUN mkdir -p /run/mysqld  \
    && chown -R mysql:mysql /run/mysqld \
    && rm -rf /var/lib/mysql/*

COPY conf/my.cnf /etc/mysql/my.cnf

COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306


CMD ["init.sh"]

