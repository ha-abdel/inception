#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
CREDENTIALS=$(cat /run/secrets/credentials)

WP_ADMIN_PASSWORD=$(echo "$CREDENTIALS" | sed -n '1p')
WP_USER_PASSWORD=$(echo  "$CREDENTIALS" | sed -n '2p')


echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" \
    2>/dev/null; do
    sleep 1
done
echo "MariaDB is ready."

if [ ! -f /var/www/html/wp-config.php ]; then


    wp core download \
        --path=/var/www/html --locale=en_US --allow-root

    wp config create \
        --path=/var/www/html --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb --allow-root

    wp core install \
        --path=/var/www/html --url="https://${DOMAIN_NAME}" \
        --title="Inception" --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email --allow-root


    wp user create \
        "${WP_USER}" "${WP_USER_EMAIL}" --path=/var/www/html \
        --role=author --user_pass="${WP_USER_PASSWORD}" --allow-root

    wp plugin install redis-cache \
    --path=/var/www/html --activate --allow-root

    wp config set WP_REDIS_HOST redis --path=/var/www/html --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --path=/var/www/html --allow-root

    wp redis enable --path=/var/www/html --allow-root

    chown -R www-data:www-data /var/www/html
fi

exec php-fpm8.2 -F