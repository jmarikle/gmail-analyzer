# Makefile for Gmail Analyzer Docker App

# set DOCKER_CLI_HINTS=false to disable Docker CLI hints because they're annoying
export DOCKER_CLI_HINTS=false

# Variables
IMAGE_NAME = gmail-analyzer
DOCKER = docker
DOCKER_HUB_USERNAME = jmarikle

# Platform targets
PLATFORMS = linux/amd64,linux/arm64

# Version handling - prioritize CLI argument, fall back to git tag, finally fall back to default
DEFAULT_VERSION = 0.1.0
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo $(DEFAULT_VERSION))

# Extract major, minor, patch versions for tagging
MAJOR_VERSION = $(shell echo $(VERSION) | cut -d. -f1)
MINOR_VERSION = $(shell echo $(VERSION) | cut -d. -f2)
PATCH_VERSION = $(shell echo $(VERSION) | cut -d. -f3)
MAJOR_MINOR = $(MAJOR_VERSION).$(MINOR_VERSION)

# Define tag list based on version
DOCKER_TAGS = -t $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(VERSION)

# Add major.minor tag if not starting with 0.0
ifneq ($(MAJOR_MINOR),0.0)
	DOCKER_TAGS += -t $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(MAJOR_MINOR)
endif
# Add major tag if not starting with 0
ifneq ($(MAJOR_VERSION),0)
    DOCKER_TAGS += -t $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(MAJOR_VERSION)
endif

DOCKER_TAGS += -t $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):latest

# Get the Docker credential helper being used
DOCKER_CONFIG_FILE = ${HOME}/.docker/config.json
CRED_HELPER = $(shell if [ -f $(DOCKER_CONFIG_FILE) ]; then grep '"credsStore"' $(DOCKER_CONFIG_FILE) 2>/dev/null | cut -d'"' -f4; fi)
ifeq ($(CRED_HELPER),)
CRED_HELPER = $(shell if [ -f $(DOCKER_CONFIG_FILE) ]; then grep '"credHelper"' $(DOCKER_CONFIG_FILE) 2>/dev/null | cut -d'"' -f4; fi)
endif

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help target
help: check-version
	@echo "${GREEN}Gmail Analyzer Docker Commands${NC}"
	@echo
	@echo "Available targets:"
	@echo "  ${GREEN}build${NC}                  - Build the Docker image for local testing"
	@echo "  ${GREEN}push${NC}                   - Build and push multi-architecture images"
	@echo "  ${GREEN}run${NC}                    - Run the Gmail analyzer in a container"
	@echo "  ${GREEN}clean${NC}                  - Remove the Docker image"
	@echo "  ${GREEN}version${NC}                - Display current version"
	@echo
	@echo "${YELLOW}Current version: ${VERSION}${NC}"
	@echo "${YELLOW}Tags that will be created:${NC}"
	@for tag in $(DOCKER_TAGS); do if [ ! "$$tag" = "-t" ]; then echo "  $$tag"; fi; done
	@echo
	@echo "${YELLOW}Supported platforms: ${PLATFORMS}${NC}"


# Verify version format and validity
check-version:
	@if ! echo $(VERSION) | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "${RED}Error: Version must be in format X.Y.Z (e.g., 2.3.4)${NC}"; \
		exit 1; \
	fi
	@if [ "$(MAJOR_VERSION)" = "0" ] && [ "$(MINOR_VERSION)" = "0" ]; then \
		echo "${RED}Error: Version cannot start with 0.0${NC}"; \
		exit 1; \
	fi

# Check Docker Hub login status using credential helper
check-docker-login:
	@if [ -z "$(CRED_HELPER)" ]; then \
		echo "${RED}Error: No Docker credential helper configured${NC}"; \
		echo "Please run 'docker login' to set up credentials"; \
		exit 1; \
	fi
	@if ! docker-credential-$(CRED_HELPER) list | grep -q "https://index.docker.io/v1/"; then \
		echo "${RED}Error: Not logged in to Docker Hub. Please run 'docker login' first.${NC}"; \
		exit 1; \
	fi

# Create and use buildx builder
setup-buildx:
	@echo "${GREEN}Setting up Docker buildx...${NC}"
	docker buildx create --use --name multiarch-builder || true

# Display current version
version:
	@echo "${GREEN}Current version: ${VERSION}${NC}"
	@echo "${YELLOW}Tags that will be created:${NC}"
	@for tag in $(DOCKER_TAGS); do if [ ! "$$tag" = "-t" ]; then echo "  $$tag"; fi; done

# Build the Docker image
build:
	@echo "${GREEN}Building Docker image version ${VERSION}...${NC}"
	$(DOCKER) build -t $(IMAGE_NAME):$(VERSION) .
	$(DOCKER) tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest
	@if [ ! "$(MAJOR_MINOR)" = "0.0" ]; then \
		$(DOCKER) tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MAJOR_MINOR); \
	fi
	@if [ ! "$(MAJOR_VERSION)" = "0" ]; then \
		$(DOCKER) tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MAJOR_VERSION); \
	fi

# Run the container
run:
	@echo "${GREEN}Running Gmail analyzer version ${VERSION}...${NC}"
	$(DOCKER) run --rm -it \
		-p 8080:8080 \
		-v $(PWD):/app \
		-v $(PWD)/data:/data \
		$(IMAGE_NAME):$(VERSION)

# Build and push multi-architecture images
push: check-docker-login check-version setup-buildx
	@echo "${GREEN}Building and pushing multi-architecture images version ${VERSION}...${NC}"
	$(DOCKER) buildx build \
		--platform $(PLATFORMS) \
		$(DOCKER_TAGS) \
		--push \
		.

# Remove the Docker image
clean:
	@echo "${GREEN}Removing Docker images...${NC}"
	-$(DOCKER) rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest 2>/dev/null || true
	-$(DOCKER) rmi $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	-$(DOCKER) rmi $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):latest 2>/dev/null || true
	-$(DOCKER) buildx rm multiarch-builder 2>/dev/null || true

.PHONY: help check-version check-docker-login setup-buildx version build run push clean
