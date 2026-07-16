#!/bin/bash
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[NOTE] initializing MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    mysqld --user=mysql --socket=/run/mysqld/mysqld.sock &
    MYSQL_PID=$!

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
    wait $MYSQL_PID 2>/dev/null || true
fi


echo " starting MariaDB..."
exec mysqld --user=mysql --console
