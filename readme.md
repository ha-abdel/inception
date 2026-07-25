*This project has been created as part of the 42 curriculum by abdel-ha.*

---

# Inception

A complete Docker-based infrastructure deploying a WordPress website with its full service stack, built entirely from scratch without any pre-built application images.

---

## Description

Inception is a system administration project from the 42 curriculum. The goal is to design and deploy a small but complete web infrastructure using Docker and Docker Compose, where every service runs in its own dedicated container built from a custom Dockerfile.

### What the project builds

The mandatory infrastructure consists of three containers communicating over a private Docker network:

- **NGINX** — the sole entry point, handles TLS termination (TLSv1.2/1.3 only) and acts as a reverse proxy forwarding PHP requests to WordPress via FastCGI
- **WordPress + PHP-FPM** — the application layer, runs without NGINX inside (PHP-FPM only)
- **MariaDB** — the relational database storing all WordPress content

Five bonus services extend the stack:

- **Redis** — object cache for WordPress, reduces database load on repeated requests
- **FTP server** (vsftpd) — direct file access to the WordPress volume for theme and plugin management
- **Static website** — a personal portfolio page served on port 8080, written in plain HTML/CSS (no PHP)
- **Adminer** — single-file PHP database management UI, accessible on port 8081
- **Homer** — a lightweight static service dashboard linking all services, served on port 8082

### Project structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt        # WordPress admin + user passwords (one per line)
│   ├── db_password.txt        # MariaDB WordPress user password
│   ├── db_root_password.txt   # MariaDB root password
│   └── ftp_password.txt       # FTP user password
└── srcs/
    ├── .env                   # Non-secret environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        ├── nginx/
        ├── wordpress/
        └── bonus/
            ├── adminer/
            ├── ftp/
            ├── homer/
            ├── redis/
            └── website/
```

---

## Project Description — Design Choices and Key Concepts

### Use of Docker

Docker allows each service to run in an isolated, reproducible environment. Every container in this project is built from a custom Dockerfile based on `debian:bookworm`. No pre-built application images (such as the official `wordpress` or `mariadb` images from Docker Hub) are used — the subject explicitly forbids this. Every dependency is installed manually, every configuration file is written by hand, and every startup script is authored from scratch.

This approach means:
- Full understanding and control of every layer in the image
- No hidden behaviour from upstream images
- Reproducible builds pinned to specific package versions
- Security through explicit, minimal installations (`--no-install-recommends`)

### Design choices

**One process per container.** Each container runs a single service as PID 1. This follows Docker best practices: a container lives and dies with its process. All init scripts use `exec` at the end to replace the shell with the service process, ensuring Docker signals (SIGTERM on `docker stop`) reach the real process for clean shutdown.

**Secrets over environment variables for passwords.** All passwords are stored in Docker secret files mounted at `/run/secrets/<name>` inside containers. They are never passed as environment variables, never appear in Dockerfiles, and never appear in `docker inspect` output. Non-sensitive configuration (database names, usernames, domain) uses environment variables via the `.env` file.

**Named volumes with local bind driver.** Data is persisted using Docker named volumes configured with the `local` driver and `bind` option, storing data at `/home/abdel-ha/data/` on the host. This satisfies the subject requirement for a specific host path while using the named volume API.

**Custom bridge network.** All containers communicate over a single custom Docker bridge network named `inception`. Docker's built-in DNS resolves container names as hostnames (e.g. WordPress connects to MariaDB using the hostname `mariadb`). The only port exposed to the host is 443 on NGINX — all other inter-container communication is internal.

**Idempotent init scripts.** All setup scripts (MariaDB's `init.sh`, WordPress's `setup.sh`) guard against re-running on container restart. They check for the presence of already-initialised state (e.g. `/var/lib/mysql/mysql/`, `wp-config.php`) before executing setup steps. This ensures container restarts are fast and data is never overwritten.

---

### Virtual Machines vs Docker

| | Virtual Machine | Docker Container |
|---|---|---|
| **Isolation level** | Full hardware virtualisation — own kernel | Process-level isolation — shares host kernel |
| **Size** | GBs (full OS per VM) | MBs (only app + dependencies) |
| **Startup time** | Minutes (full OS boot) | Milliseconds (single process start) |
| **Resource overhead** | High — each VM duplicates kernel, init system, drivers | Low — kernel shared, only app processes run |
| **Use case** | Strong isolation, different OS, legacy software | Microservices, consistent deployment, CI/CD |
| **Persistence** | VM disk image | Named volumes or bind mounts |
| **Portability** | Limited — hypervisor-dependent | High — runs identically on any Docker host |

In this project, Docker is the right choice because all services run on the same Linux kernel, they only need process-level isolation, and the lightweight nature allows the full stack to run comfortably on a 42 school VM.

---

### Secrets vs Environment Variables

| | Docker Secrets | Environment Variables |
|---|---|---|
| **Storage** | File at `/run/secrets/<name>` inside container | `$VAR` in process environment |
| **Visibility in `docker inspect`** | Not shown | Shown in plain text |
| **Visibility in `/proc/<pid>/environ`** | Not present | Present — any process can read |
| **Risk of accidental logging** | Low — must explicitly `cat` the file | High — many tools log env vars |
| **Use case in this project** | All passwords (DB, WordPress, FTP) | Non-secret config (domain, usernames, DB name) |

Environment variables are used for values that are not sensitive and need to be referenced across multiple services. Secrets are used for any value that, if leaked, would compromise the infrastructure.

---

### Docker Network vs Host Network

| | Custom Bridge Network (`driver: bridge`) | Host Network (`--network host`) |
|---|---|---|
| **Isolation** | Containers are isolated from the host network | Container shares the host's network namespace completely |
| **DNS** | Docker provides built-in DNS — container names resolve as hostnames | No Docker DNS — must use IPs or configure DNS manually |
| **Port exposure** | Controlled — only `ports:` mappings are reachable from outside | All listening ports on the container are immediately on the host |
| **Security** | Strong — contained blast radius | Weak — container can interfere with host network stack |
| **Used in this project** | Yes — `inception` bridge network | Forbidden by the subject |

The custom bridge network is the correct choice for this project. It provides DNS-based service discovery (`mariadb`, `wordpress`, `redis` resolve automatically), limits external exposure to only port 443, and satisfies the subject's explicit prohibition on host networking.

---

### Docker Volumes vs Bind Mounts

| | Named Volumes | Bind Mounts |
|---|---|---|
| **Definition** | Declared in `volumes:` section, managed by Docker | A host path mapped directly into the container |
| **Host path control** | Docker chooses path (`/var/lib/docker/volumes/`) unless driver_opts are used | You specify the exact host path |
| **Portability** | Portable — works on any Docker host | Path must exist on the specific host |
| **Used for services** | Yes — `db_data`, `wordpress_files`, `portainer_data` | Forbidden in service definitions by the subject |
| **Driver opts workaround** | `driver: local` + `o: bind` + `device: /home/abdel-ha/data/...` | — |

In this project, named volumes are used in the `services:` section (as required by the subject), but the `driver_opts` in the `volumes:` section pin the physical storage location to `/home/abdel-ha/data/` on the host. This is not the same as a bind mount in a service — it uses the Docker volume API with a local bind driver, which satisfies both the subject requirement and the need for a specific host path.

---

## Instructions

### Prerequisites

- Docker Engine (20.10+)
- Docker Compose plugin (`docker compose` v2)
- `make`
- A 42 school VM running Linux (or any Debian-based system)

### 1 — Clone the repository

```bash
git clone https://github.com/abdel-ha/inception.git
cd inception
```

### 2 — Create secret files

```bash
mkdir -p secrets

# MariaDB root password
echo "YourRootPassword42!" > secrets/db_root_password.txt

# MariaDB WordPress user password
echo "YourDbPassword42!" > secrets/db_password.txt

# WordPress passwords: admin password on line 1, user password on line 2
printf "YourAdminPass42!\nYourUserPass42!" > secrets/credentials.txt

# FTP password
echo "YourFtpPass42!" > secrets/ftp_password.txt
```

### 3 — Configure the environment

Edit `srcs/.env` and set your 42 login and VM IP:

```bash
DOMAIN_NAME=abdel-ha.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_ADMIN_USER=wpmaster
WP_ADMIN_EMAIL=wpmaster@abdel-ha.42.fr
WP_USER=wpreader
WP_USER_EMAIL=wpreader@abdel-ha.42.fr
DATA_PATH=/home/abdel-ha/data
FTP_HOST=10.0.2.15   # your VM's IP address
```

### 4 — Add the domain to `/etc/hosts`

```bash
echo "127.0.0.1 abdel-ha.42.fr" | sudo tee -a /etc/hosts
```

### 5 — Build and start

```bash
make
```

This creates the host data directories, builds all Docker images, and starts all containers.

### 6 — Access the services

| Service | URL |
|---|---|
| WordPress | https://abdel-ha.42.fr |
| Adminer | http://abdel-ha.42.fr:8081 |
| Portfolio | http://abdel-ha.42.fr:8080 |
| Homer dashboard | http://abdel-ha.42.fr:8082 |
| Portainer | https://abdel-ha.42.fr:9443 |

### Stopping and cleaning

```bash
make down      # stop containers, keep volumes and data
make clean     # stop containers and delete all data
make fclean    # full wipe including Docker images
make re        # full wipe and rebuild from scratch
```

---

## Resources

### Official documentation

- [Docker Engine documentation](https://docs.docker.com/engine/) — core concepts, Dockerfile reference, networking, volumes
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/) — compose file specification
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/) — server configuration, SQL reference
- [NGINX documentation](https://nginx.org/en/docs/) — configuration directives, location matching, FastCGI
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php) — pool settings, process management
- [WordPress WP-CLI handbook](https://make.wordpress.org/cli/handbook/) — command reference for non-interactive WordPress management
- [OpenSSL man page](https://www.openssl.org/docs/man3.0/man1/openssl-req.html) — certificate generation options
- [vsftpd manual](https://security.appspot.com/vsftpd/vsftpd_conf.html) — FTP server configuration
- [Redis configuration](https://redis.io/docs/management/config-file/) — server options, memory management

### Articles and tutorials

- [Docker networking deep dive](https://docs.docker.com/network/) — bridge, host, overlay networks explained
- [Understanding Linux namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html) — the kernel feature Docker is built on
- [Linux cgroups overview](https://man7.org/linux/man-pages/man7/cgroups.7.html) — resource control for containers
- [NGINX FastCGI guide](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/) — connecting NGINX to PHP-FPM
- [WordPress Object Cache](https://developer.wordpress.org/reference/classes/wp_object_cache/) — how WordPress caching works internally
- [TLS 1.2 vs 1.3 differences](https://www.cloudflare.com/learning/ssl/why-use-tls-1.3/) — handshake improvements and cipher changes

### AI usage in this project

Claude (Anthropic) was used as a learning and implementation assistant throughout this project. Specific uses:

- **Understanding Docker internals** — Linux namespaces, cgroups, OverlayFS, and how they combine to form containers; the difference between image layers and the writable container layer
- **Understanding MariaDB** — how `mysqld` starts, the role of `mysql_install_db`, unix socket vs TCP authentication, and why `'%'` is needed for the WordPress user host
- **Understanding PHP-FPM** — the FastCGI protocol, worker pool management (`pm = dynamic`), why `listen = 0.0.0.0:9000` is required in a multi-container setup
- **Understanding NGINX** — TLS termination, location block precedence, `try_files` fallback for WordPress pretty permalinks, `daemon off` for Docker PID 1
- **Writing init scripts** — the pattern of `exec` to replace the shell as PID 1, idempotency guards, secret file reading, readiness loops
- **Debugging** — interpreting Docker log output, diagnosing the MariaDB `unauthenticated` connection warnings, understanding the `'%'` vs `'localhost'` user host distinction

AI was used to deepen understanding and validate reasoning, not to blindly generate code. Every configuration line, every script, and every design decision in this project was understood, questioned, and intentionally chosen.



# resources

https://www.digitalocean.com/community/tutorials/install-wordpress-nginx-ubuntu

https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose


https://www.digitalocean.com/community/tutorials/how-to-use-wp-cli-to-manage-your-wordpress-site-from-the-command-line


