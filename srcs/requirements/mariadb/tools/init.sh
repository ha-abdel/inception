#!/bin/bash
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# check if mysql database exists.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[NOTE] initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
    mysqld --user=mysql --socket=/run/mysqld/mysqld.sock &
    MYSQL_PID=$!

    # 2>&1 means redirect stderr where stdout is redirected which is /dev/null
    until mysql -u root --socket=/run/mysqld/mysqld.sock -e "SELECT 1" > /dev/null 2>&1; do
        sleep 0.5
    done

    mysql -u root --socket=/run/mysqld/mysqld.sock << EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    DELETE FROM mysql.user WHERE User='';
    FLUSH PRIVILEGES;
EOF

    kill $MYSQL_PID
    # EVEN IF THE KILL WAIT FAILS WHICH MEANS THE PROCESS ALREADY DIED THE STATEMENT IS TRUE
    wait $MYSQL_PID 2>/dev/null || true
fi


echo " starting MariaDB..."
# --user=mysql Runs the server as the 'mysql' system user for wordpress.
# --console  Writes log output to STDOUT (console) instead of log files.
exec mysqld --user=mysql --console
