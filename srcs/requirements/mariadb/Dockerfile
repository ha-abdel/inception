# ── Base image ────────────────────────────────────────────────────────────────
# penultimate stable Debian (bookworm = Debian 12, current stable as of 2024/25)
# "latest" tag is forbidden by the project — always pin to a specific release
FROM debian:bookworm

# ── Install MariaDB ───────────────────────────────────────────────────────────
# We chain all apt commands in ONE RUN to keep it as a single layer.
# If each apt command were a separate RUN, we'd get 3 layers where 1 suffices.
# --no-install-recommends: skip optional packages → smaller image
# rm -rf /var/lib/apt/lists/*: delete the apt package index after install
# → the index is only needed during build, removing it shrinks the final image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# ── Create the mysqld run directory ──────────────────────────────────────────
# MariaDB writes its socket file to /run/mysqld/
# This directory doesn't exist in the base debian image
# chown mysql:mysql → the mysql user (created by the mariadb-server package)
#                     must own this dir to write the socket file
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# ── Copy our custom server configuration ─────────────────────────────────────
# Overwrites the default my.cnf with our tuned version
# (sets bind-address, datadir, charset, etc.)
COPY conf/my.cnf /etc/mysql/my.cnf

# ── Copy the init/entrypoint script ──────────────────────────────────────────
COPY tools/init.sh /usr/local/bin/init.sh

# Make it executable — COPY does not preserve the executable bit by default
RUN chmod +x /usr/local/bin/init.sh

# ── Expose the MariaDB port ───────────────────────────────────────────────────
# EXPOSE is documentation — it tells Docker (and humans) which port this
# container listens on. It does NOT publish the port to the host.
# MariaDB's port is only reachable from within the docker network.
EXPOSE 3306

# ── Entrypoint ────────────────────────────────────────────────────────────────
# CMD vs ENTRYPOINT:
#   ENTRYPOINT — the main executable; cannot be easily overridden at runtime
#   CMD        — default arguments to ENTRYPOINT, can be overridden
# Here we use CMD alone so `docker run` can override for debugging.
# init.sh ends with `exec mysqld ...` which becomes PID 1.
CMD ["init.sh"]