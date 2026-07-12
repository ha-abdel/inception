set -e

# ── 1. Read secrets ───────────────────────────────────────────────────────────
DB_PASSWORD=$(cat /run/secrets/db_password)
CREDENTIALS=$(cat /run/secrets/credentials)

WP_ADMIN_PASSWORD=$(echo "$CREDENTIALS" | sed -n '1p')
WP_USER_PASSWORD=$(echo  "$CREDENTIALS" | sed -n '2p')


echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" \
      --silent 2>/dev/null; do
    sleep 1
done
echo "MariaDB is ready."

if [ ! -f /var/www/html/wp-config.php ]; then


    wp core download \
        --path=/var/www/html \
        --locale=en_US \
        --allow-root

    wp config create \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root


    wp user create \
        --path=/var/www/html \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    chown -R www-data:www-data /var/www/html
fi

exec php-fpm8.2 -F