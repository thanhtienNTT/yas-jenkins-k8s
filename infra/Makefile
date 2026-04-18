.PHONY: help env jenkins-up jenkins-down jenkins-logs jenkins-rebuild jenkins-reset

JENKINS_DIR := jenkins
ENV_FILE := .env
ENV_TEMPLATE := .env.example

help:
	@echo "make env             # Create .env from .env.example"
	@echo "make jenkins-up      # Build and start Jenkins"
	@echo "make jenkins-down    # Stop Jenkins"
	@echo "make jenkins-logs    # Follow Jenkins logs"
	@echo "make jenkins-rebuild # Rebuild Jenkins image"
	@echo "make jenkins-reset   # Remove Jenkins container and data"

env:
	@if [ -f $(ENV_FILE) ]; then \
		echo ".env already exists"; \
	else \
		cp $(ENV_TEMPLATE) $(ENV_FILE); \
		echo "Created .env from .env.example"; \
	fi

jenkins-up: env
	@mkdir -p jenkins_data
	@touch kubeconfig
	@cd $(JENKINS_DIR) && docker compose --env-file ../.env up -d --build

jenkins-down:
	@cd $(JENKINS_DIR) && docker compose --env-file ../.env down

jenkins-logs:
	@cd $(JENKINS_DIR) && docker compose --env-file ../.env logs -f --tail=200

jenkins-rebuild:
	@cd $(JENKINS_DIR) && docker compose --env-file ../.env build --no-cache

jenkins-reset:
	@cd $(JENKINS_DIR) && docker compose --env-file ../.env down -v --remove-orphans
