#!/bin/bash
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# 1. Create FTP user (if not exists) and set password
useradd -m -d /var/www/html -s /bin/bash ${FTP_USER} || true
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

# 2. Add to vsftpd userlist
echo "${FTP_USER}" > /etc/vsftpd.userlist

# 3. Permissions – add to www-data group and set write access
usermod -aG www-data ${FTP_USER}
chmod -R 775 /var/www/html || true

# 4. Inject FTP_HOST into config file
envsubst '${FTP_HOST}' < /etc/vsftpd.conf > /tmp/vsftpd.conf.rendered
mv /tmp/vsftpd.conf.rendered /etc/vsftpd.conf

exec vsftpd /etc/vsftpd.conf