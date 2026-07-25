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
| **Homer** | Dashboard linking all services | http://abdel-ha.42.fr:8085 |
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


### Adminer — database panel

```
http://abdel-ha.42.fr:8081
```


### Homer dashboard

```
http://abdel-ha.42.fr:8085
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