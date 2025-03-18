# Makefile to build Nautobot container
# Author: Benjamin P. Trachtenberg
# Version: 2025.3.18.001

.PHONY: build-podman-nautobot build-docker-nautobot

info:
	@echo "make options"
	@echo "    build-podman-nautobot             To build the container in podman"
	@echo "    build-docker-nautobot             To build the container in docker"

build-podman-nautobot:
	@echo "Building the nautobot container with container_version=$(container_version) in podman"
	@podman build --tag nauotbot-ntc-custom:latest --tag nauotbot-ntc-custom:$(container_version) -f Containerfile --format docker

build-docker-nautobot:
	@echo "Building the nautobot container with container_version=$(container_version) in docker"
	@docker build --tag nauotbot-ntc-custom:latest --tag nauotbot-ntc-custom:$(container_version) -f Containerfile .
