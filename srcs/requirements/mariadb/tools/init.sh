#!/bin/bash
# init.sh — initialise MariaDB database, users, and permissions
# This script is the ENTRYPOINT: it runs once at container start,
# sets everything up, then hands control to mysqld (the real daemon).

set -e  # exit immediately if any command fails

# ── 1. Bootstrap the data directory ──────────────────────────────────────────
# mysql_install_db creates the system tables in /var/lib/mysql
# if they do not already exist (i.e. first boot with empty volume).
# --user=mysql runs the process as the mysql user, not root.
# --datadir matches the path in my.cnf.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# ── 2. Start a temporary mysqld to run setup SQL ──────────────────────────────
# We start mysqld in the background with --bootstrap-like settings
# so we can run SQL without a fully running server.
# --skip-networking disables TCP so nothing external can connect yet.
mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
MYSQL_PID=$!

# Wait until the socket file appears — that means mysqld is ready
until mysql -u root --socket=/run/mysqld/mysqld.sock -e "SELECT 1" > /dev/null 2>&1; do
    sleep 0.5
done

# ── 3. Read secrets from Docker secret files ──────────────────────────────────
# Docker secrets are mounted at /run/secrets/<name>
# Reading from files (not env vars) is more secure — secrets never appear
# in `docker inspect` output or process environment listings.
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# ── 4. Run setup SQL ──────────────────────────────────────────────────────────
mysql -u root --socket=/run/mysqld/mysqld.sock << EOF

-- Set a strong root password (root has no password after mysql_install_db)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Create the WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create the WordPress application user (used by wp-config.php)
-- '%' means this user can connect from ANY host — needed because
-- WordPress runs in a different container.
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

-- Give the WordPress user full rights on the WordPress database only
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Remove the anonymous user that mysql_install_db creates
DELETE FROM mysql.user WHERE User='';

-- Flush so changes take effect immediately
FLUSH PRIVILEGES;
EOF

# ── 5. Stop the temporary server ──────────────────────────────────────────────
kill $MYSQL_PID
wait $MYSQL_PID 2>/dev/null || true

# ── 6. Exec the real mysqld as PID 1 ─────────────────────────────────────────
# `exec` REPLACES this shell process with mysqld.
# This means mysqld becomes PID 1 — exactly what Docker needs.
# --user=mysql: never run the database as root
# --console: log to stdout so `docker logs` can see it
exec mysqld --user=mysql --console