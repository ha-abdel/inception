FROM debian:12

RUN apt-get update && apt-get install -y \
    wget && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/portainer.tar.gz \
    https://github.com/portainer/portainer/releases/download/2.39.5/portainer-2.39.5-linux-amd64.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /usr/local/ \
    && rm /tmp/portainer.tar.gz

WORKDIR /usr/local/portainer

EXPOSE 9000

CMD ["./portainer"]