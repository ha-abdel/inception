COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR     = /home/abdel-ha/data

all: create_dirs up

create_dirs:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

up:
	docker compose -f $(COMPOSE_FILE) up --build

down:
	docker compose -f $(COMPOSE_FILE) down

clean: down
	docker compose -f $(COMPOSE_FILE) down -v
	sudo rm -rf $(DATA_DIR)/mariadb/
	sudo rm -rf $(DATA_DIR)/wordpress/

fclean: clean
# 	docker system prune -af

re: fclean all

status:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

.PHONY: all create_dirs up down clean fclean re status logs