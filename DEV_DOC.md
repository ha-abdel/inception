# DEV_DOC.md — Developer Documentation

This document describes how to set up, build, run, debug, and maintain the Inception infrastructure from a developer's perspective. It assumes familiarity with Linux, the command line, and basic Docker concepts.

---

## Prerequisites

### Required software

| Tool | Minimum version | Check |
|---|---|---|
| Docker Engine | 20.10+ | `docker --version` |
| Docker Compose plugin | v2 (uses `docker compose`, not `docker-compose`) | `docker compose version` |
| GNU Make | any | `make --version` |
| OpenSSL | 1.1+ | `openssl version` |

### Installing Docker on Debian/Ubuntu (42 VM)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow your user to run docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

---

## Setting up from scratch

### 1 — Clone the repository

```bash
git clone https://github.com/abdel-ha/inception.git
cd inception
```

### 2 — Create the secret files

Secrets are never stored in Git. You must create them manually on every new machine.

```bash
mkdir -p secrets

# MariaDB root password (used only during database initialisation)
echo "RootSecurePass42!" > secrets/db_root_password.txt

# MariaDB application user password (used by WordPress to connect)
echo "WpDbSecurePass42!" > secrets/db_password.txt

# WordPress credentials: admin password on line 1, regular user on line 2
# Admin username must NOT contain "admin" — see .env for the username
printf "AdminSecurePass42!\nUserSecurePass42!" > secrets/credentials.txt

# FTP user password
echo "FtpSecurePass42!" > secrets/ftp_password.txt
```

### 3 — Configure environment variables

Edit `srcs/.env`:

```bash
DOMAIN_NAME=abdel-ha.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_ADMIN_USER=wpmaster
WP_ADMIN_EMAIL=wpmaster@abdel-ha.42.fr

WP_USER=wpreader
WP_USER_EMAIL=wpreader@abdel-ha.42.fr

DATA_PATH=/home/abdel-ha/data

FTP_HOST=10.0.2.15
```

### 4 — Configure local DNS

The domain `abdel-ha.42.fr` must resolve to the VM's loopback address for local development:

```bash
echo "127.0.0.1 abdel-ha.42.fr" | sudo tee -a /etc/hosts
```

Verify:
```bash
ping -c 1 abdel-ha.42.fr
# should show: PING abdel-ha.42.fr (127.0.0.1)
```

### 5 — Build and launch

```bash
make
```

The Makefile runs:
1. `create_dirs` — creates `/home/abdel-ha/data/{mariadb,wordpress,portainer}` on the host
2. `docker compose up -d --build` — builds all images and starts all containers

---

## Building and launching with Make

All operations are done via the Makefile at the project root.

```makefile
make           # create dirs + build images + start containers (detached)
make up        # build images + start containers (without creating dirs)
make down      # stop and remove containers (volumes preserved)
make clean     # stop containers + delete all volume data
make fclean    # clean + remove all Docker images built by this project
make re        # fclean + full rebuild from scratch
make status    # show container status (docker compose ps)
make logs      # follow logs from all containers (Ctrl+C to exit)
```

### Forcing a full rebuild of one service

```bash
docker compose -f srcs/docker-compose.yml build --no-cache mariadb
docker compose -f srcs/docker-compose.yml up -d mariadb
```

### Rebuilding after changing a Dockerfile or script

Any change to a Dockerfile, config file, or tool script requires a rebuild of that image:

```bash
# Example: you changed srcs/requirements/nginx/tools/entrypoint.sh
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

---

## Container management commands

### Inspecting running containers

```bash
# List all containers with status
docker compose -f srcs/docker-compose.yml ps

# Full details of a container (network, mounts, env vars, restart policy)
docker inspect mariadb

# Resource usage (CPU, RAM, network I/O)
docker stats
```

### Executing commands inside containers

```bash
# Open a bash shell in any container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
docker exec -it redis bash


### Reading logs

```bash
# Follow all containers
docker compose -f srcs/docker-compose.yml logs -f

# Follow a specific container
docker logs -f mariadb
docker logs -f wordpress
docker logs -f nginx


```

### Managing containers individually

```bash
# Stop a single container
docker stop nginx

# Start it again
docker start nginx

# Restart
docker restart wordpress

# Force kill (avoid — bypasses graceful shutdown)
docker kill mariadb
```

---

## Volume and data management

### Where data is stored

All persistent data lives on the host under `/home/abdel-ha/data/`:

```
/home/abdel-ha/data/
├── mariadb/          ← all MariaDB database files
│   ├── mysql/        ← system tables, users, privileges
│   ├── wordpress/    ← WordPress database tables
│   ├── ibdata1       ← InnoDB shared tablespace
│   └── ib_logfile*   ← InnoDB redo logs (crash recovery)
└── wordpress/        ← WordPress application files
    ├── wp-config.php ← DB credentials, keys, salts
    ├── wp-content/   ← themes, plugins, uploaded media
    └── wp-*.php      ← WordPress core files
```

These directories are mounted into containers via Docker named volumes:

| Volume name | Host path | Container mount point | Used by |
|---|---|---|---|
| `db_data` | `/home/abdel-ha/data/mariadb` | `/var/lib/mysql` | mariadb |
| `wordpress_files` | `/home/abdel-ha/data/wordpress` | `/var/www/html` | wordpress, nginx, ftp |

### Inspecting volumes

```bash
# List all volumes
docker volume ls

```

### Data lifecycle

| Action | Data preserved? |
|---|---|
| `docker stop` / `docker start` | Yes |
| `docker restart` | Yes |
| `docker compose down` (no flags) | Yes |
| Container crash + auto-restart | Yes |
| `docker compose down -v` | **No — volumes deleted** |
| `make clean` | **No — volumes and host dirs wiped** |
| `make fclean` | **No — everything wiped** |

---

## Network architecture

### Inspecting the Docker network

```bash
# List all networks
docker network ls

```

### Container IPs and DNS

Within the `inception` network, each container is reachable by its container name. Docker's embedded DNS server resolves these names automatically:

| Container name | Reachable at (inside Docker network) | Exposed to host |
|---|---|---|
| `nginx` | `nginx:443` | Yes — host port 443 |
| `wordpress` | `wordpress:9000` | No |
| `mariadb` | `mariadb:3306` | No |
| `redis` | `redis:6379` | No |
| `ftp` | `ftp:21` | Yes — host ports 21, 21100-21110 |
| `adminer` | `adminer:8081` | Yes — host port 8081 |
| `website` | `website:8080` | Yes — host port 8080 |
| `homer` | `homer:8085` | Yes — host port 8085 |


---