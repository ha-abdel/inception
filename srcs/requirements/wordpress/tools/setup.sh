#!/bin/bash
# setup.sh — install and configure WordPress, then start PHP-FPM
# This script runs every time the container starts (not just first boot).
# It's idempotent: it skips steps already done.

set -e

# ── 1. Read secrets ───────────────────────────────────────────────────────────
DB_PASSWORD=$(cat /run/secrets/db_password)
CREDENTIALS=$(cat /run/secrets/credentials)
# credentials.txt format: two lines → wp_admin_password on line 1,
# wp_user_password on line 2
WP_ADMIN_PASSWORD=$(echo "$CREDENTIALS" | sed -n '1p')
WP_USER_PASSWORD=$(echo  "$CREDENTIALS" | sed -n '2p')

# ── 2. Wait for MariaDB to be ready ──────────────────────────────────────────
# The wordpress container might start before mariadb finishes initialising.
# We use mysqladmin ping to check — retry every second until it responds.
echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" \
      --silent 2>/dev/null; do
    sleep 1
done
echo "MariaDB is ready."

# ── 3. Install WordPress files (only on first boot) ───────────────────────────
# /var/www/html is mounted from the shared volume.
# If wp-config.php already exists, WordPress was already installed → skip.
if [ ! -f /var/www/html/wp-config.php ]; then

    # Download WordPress core using WP-CLI
    # --allow-root: WP-CLI refuses to run as root by default; this bypasses it.
    # We're in a container so running as root during setup is acceptable.
    wp core download \
        --path=/var/www/html \
        --locale=en_US \
        --allow-root

    # Generate wp-config.php with our database credentials.
    # We pass the password via env var substitution here — it never touches
    # the Dockerfile or the image layers.
    wp config create \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    # Run the WordPress installer.
    # --admin_user: the subject forbids names containing "admin"/"administrator"
    # Change "wpmaster" to whatever username you want.
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Create a second (non-admin) WordPress user — required by the subject
    wp user create \
        --path=/var/www/html \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    # Fix ownership: the web files must be readable by www-data (PHP-FPM's user)
    chown -R www-data:www-data /var/www/html
fi

# ── 4. Start PHP-FPM as PID 1 ─────────────────────────────────────────────────
# -F = foreground mode (don't daemonize — critical for Docker PID 1)
# exec replaces this shell with php-fpm so php-fpm IS PID 1
# The PHP version must match what was installed (adjust 8.2 if needed)
exec php-fpm8.2 -F