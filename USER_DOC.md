# USER_DOC.md — User Documentation

This document explains how to operate the Inception infrastructure as an end user or administrator. No Docker knowledge is required to follow these instructions.

---

## What services are provided

The Inception stack runs the following services simultaneously:

| Service | Purpose | Address |
|---|---|---|
| **WordPress** | Main website and content management system | https://abdel-ha.42.fr |
| **Adminer** | Web-based database management panel | http://abdel-ha.42.fr:8081 |
| **Portfolio** | Static personal website | http://abdel-ha.42.fr:8080 |
| **Homer** | Dashboard linking all services | http://abdel-ha.42.fr:8082 |
| **FTP server** | Direct file access to WordPress files | ftp://\<vm-ip\>:21 |
| **Redis** | Internal cache (no user interface — works in background) | internal only |

> **Note on HTTPS:** The WordPress site uses a self-signed TLS certificate. Your browser will show a security warning on first visit. This is expected — click "Advanced" then "Proceed" (or equivalent in your browser) to continue. The connection is still encrypted.

---

## Starting the project

Open a terminal on the server and run:

```bash
cd /path/to/inception
make
```

This single command:
1. Creates the data directories on disk
2. Builds all Docker images from source
3. Starts all containers in the correct order

The first run takes several minutes because Docker downloads base images and installs packages. Subsequent starts are much faster.

To verify everything started correctly:

```bash
make status
```

You should see all containers listed as `Up`.

---

## Stopping the project

**Stop all services (keep all data):**
```bash
make down
```
All containers stop. Your WordPress posts, database, and uploaded files are preserved. Running `make` again resumes everything exactly where you left off.

**Full reset (delete all data):**
```bash
make clean
```
Stops all containers and deletes all stored data. WordPress will need to be reinstalled on next start. Use this only when you want a completely fresh start.

---

## Accessing the website and administration panel

### WordPress front-end

Open your browser and go to:
```
https://abdel-ha.42.fr
```
Accept the certificate warning if prompted. You will see the WordPress website.

### WordPress administration panel

```
https://abdel-ha.42.fr/wp-admin
```

Log in with the administrator credentials (see the Credentials section below). From here you can:
- Write and publish posts and pages
- Install and manage themes and plugins
- Manage users
- Upload media files

### Adminer — database panel

```
http://abdel-ha.42.fr:8081
```

Use this to inspect and manage the MariaDB database directly. On the login screen:

| Field | Value |
|---|---|
| System | MySQL |
| Server | mariadb |
| Username | wpuser |
| Password | *(see db_password.txt)* |
| Database | wordpress |

> **Warning:** Adminer gives you direct access to the database. Deleting tables or rows here will break WordPress. Use it for inspection and debugging only.

### Homer dashboard

```
http://abdel-ha.42.fr:8082
```

A simple dashboard with links to all services. Start here if you are not sure which URL to use.

### Portfolio / static website

```
http://abdel-ha.42.fr:8080
```

A static personal website. No login required.

---

## Locating and managing credentials

All credentials are stored as plain text files in the `secrets/` directory at the project root. **These files must never be committed to Git.**

| File | Contents |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password (admin database access) |
| `secrets/db_password.txt` | MariaDB password for the WordPress user (`wpuser`) |
| `secrets/credentials.txt` | Line 1: WordPress admin password · Line 2: WordPress regular user password |
| `secrets/ftp_password.txt` | FTP user password |

### WordPress user accounts

| Role | Username | Email | Password location |
|---|---|---|---|
| Administrator | `wpmaster` | wpmaster@abdel-ha.42.fr | `credentials.txt` line 1 |
| Author | `wpreader` | wpreader@abdel-ha.42.fr | `credentials.txt` line 2 |

> The administrator username deliberately does not contain "admin" — this is a project requirement and also a security best practice.

### Changing a password

1. Edit the relevant file in `secrets/`
2. Run `make clean` to wipe existing data
3. Run `make` to rebuild with the new credentials

There is no hot-reload for secrets — a full rebuild is required.

---

## Checking that services are running correctly

### Quick status check

```bash
make status
```

All containers should show `Up`. If any show `Exited` or `Restarting`, check the logs.

### Reading logs

```bash
make logs
```

Shows live log output from all containers. Press `Ctrl+C` to stop following.

For a specific service:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
docker logs redis
docker logs ftp
docker logs adminer
docker logs website
docker logs homer
```

### What healthy logs look like

**MariaDB** — healthy output ends with:
```
mysqld: ready for connections.
```

**WordPress** — healthy output ends with:
```
NOTICE: fpm is running, pid 1
NOTICE: ready to handle connections
```

**NGINX** — no output after start is normal. NGINX is silent when healthy. Errors appear as `[error]` lines.

**Redis** — healthy output ends with:
```
Ready to accept connections
```

### Testing the NGINX TLS configuration

```bash
docker exec nginx nginx -t
```

Should print:
```
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Testing the database connection

```bash
docker exec mariadb mysql -u wpuser -p"$(cat secrets/db_password.txt)" wordpress -e "SHOW TABLES;"
```

Should list the WordPress database tables (`wp_posts`, `wp_users`, etc.).

### Testing Redis

```bash
docker exec redis redis-cli ping
```

Should return:
```
PONG
```

To confirm WordPress is actually using Redis:
1. Log into WordPress admin at `https://abdel-ha.42.fr/wp-admin`
2. Go to **Settings → Redis**
3. Status should show **Connected**

### Testing FTP access

Using `lftp` on the host:
```bash
lftp -u ftpuser,$(cat secrets/ftp_password.txt) ftp://$(hostname -I | awk '{print $1}')
```

Once connected, `ls` should show the WordPress files (`wp-config.php`, `wp-content/`, etc.).

---

## Automatic restarts

All containers are configured with `restart: always`. If a container crashes or the host machine reboots, Docker automatically restarts every service without manual intervention. You do not need to run `make` again after a reboot — Docker handles it.

To verify auto-restart is configured:
```bash
docker inspect mariadb | grep RestartPolicy
```

Should show `"Name": "always"`.