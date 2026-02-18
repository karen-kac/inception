# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: myokono <myokono@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/02/18 00:00:00 by myokono          #+#    #+#              #
#    Updated: 2026/02/18 00:00:00 by myokono         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception
DATA_DIR = /home/myokono/data
COMPOSE_FILE = srcs/docker-compose.yml

# Colors
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

all: setup build up

setup:
	@echo "$(BLUE)Setting up data directories...$(NC)"
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@sudo mkdir -p $(DATA_DIR)/mariadb
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)
	@docker volume inspect wordpress-data >/dev/null 2>&1 || docker volume create \
		--driver local \
		--opt type=none \
		--opt o=bind \
		--opt device=$(DATA_DIR)/wordpress \
		wordpress-data >/dev/null
	@docker volume inspect mariadb-data >/dev/null 2>&1 || docker volume create \
		--driver local \
		--opt type=none \
		--opt o=bind \
		--opt device=$(DATA_DIR)/mariadb \
		mariadb-data >/dev/null
	@echo "$(GREEN)✓ Data directories created$(NC)"
	@echo "$(BLUE)Configuring /etc/hosts...$(NC)"
	@sudo grep -q "myokono.42.fr" /etc/hosts || echo "127.0.0.1 myokono.42.fr" | sudo tee -a /etc/hosts
	@echo "$(GREEN)✓ Domain configured$(NC)"

build:
	@echo "$(BLUE)Building Docker images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)✓ Images built successfully$(NC)"

up:
	@echo "$(BLUE)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✓ Containers started$(NC)"
	@echo "$(YELLOW)WordPress is available at: https://myokono.42.fr$(NC)"

down:
	@echo "$(RED)Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

start:
	@echo "$(BLUE)Starting containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) start
	@echo "$(GREEN)✓ Containers started$(NC)"

stop:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) stop
	@echo "$(GREEN)✓ Containers stopped$(NC)"

restart: stop start

status:
	@echo "$(BLUE)Container status:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

clean: down
	@echo "$(RED)Removing images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down --rmi all
	@echo "$(GREEN)✓ Images removed$(NC)"

fclean: clean
	@echo "$(RED)Removing volumes and data...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down --volumes
	@docker volume rm -f wordpress-data mariadb-data >/dev/null 2>&1 || true
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@echo "$(GREEN)✓ All data cleaned$(NC)"

re: fclean all

prune:
	@echo "$(RED)Pruning Docker system...$(NC)"
	@docker system prune -af --volumes
	@echo "$(GREEN)✓ System pruned$(NC)"

.PHONY: all setup build up down start stop restart status logs clean fclean re prune
