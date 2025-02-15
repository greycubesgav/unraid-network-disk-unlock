# DOCKER FROM Image Settings
DOCKER_USER=greycubesgav
DOCKER_BASE_IMAGE_NAME=slackware-docker-base
DOCKER_BASE_IMAGE_TAG=aclemons
DOCKER_BASE_IMAGE_VERSION=current
# DOCKER TAG Image Settings
DOCKER_TARGET_IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel`)
DOCKER_PLATFORM=linux/amd64
BUILD_ARCH=x86_64
BUILD_COUNT=1
BUILD_TAG='_GG'
BUILD_VERSION=$(shell date +%Y.%m.%d)
# Add NOCACHE='--no-cache' to force a rebuild e.g.: make NOCACHE='--no-cache' docker-image-build-current
NOCACHE=
# Make sure we are running bash, not 'dash' under github actions
SHELL := /usr/bin/env bash

# By default, build package versions and variants
default: docker-artifact-build

docker-image-build-nocache:
	$(eval NOCACHE='--no-cache')
	@echo "Building $(DOCKER_TARGET_IMAGE_NAME) with NOCACHE=$(NOCACHE)"
	make docker-image-build NOCACHE=$(NOCACHE)

# Build the package using the variables set in the Makefile
docker-image-build:
	$(eval DOCKER_FULL_BASE_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_BASE_IMAGE_NAME):$(DOCKER_BASE_IMAGE_TAG)-$(DOCKER_BASE_IMAGE_VERSION))
	$(eval DOCKER_FULL_TARGET_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_TARGET_IMAGE_NAME):v$(BUILD_VERSION).$(BUILD_COUNT))
	@echo "Building $(DOCKER_FULL_TARGET_IMAGE_NAME) against $(DOCKER_FULL_BASE_IMAGE_NAME)"
	docker build --platform $(DOCKER_PLATFORM) --file Dockerfile \
		$(NOCACHE) \
		--build-arg DOCKER_FULL_BASE_IMAGE_NAME="$(DOCKER_FULL_BASE_IMAGE_NAME)" \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_COUNT=$(BUILD_COUNT) \
		--build-arg BUILD_TAG=$(BUILD_TAG) \
		--tag $(DOCKER_FULL_TARGET_IMAGE_NAME) .

docker-image-run:
	$(eval DOCKER_FULL_BASE_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_BASE_IMAGE_NAME):$(DOCKER_BASE_IMAGE_TAG)-$(DOCKER_BASE_IMAGE_VERSION))
	$(eval DOCKER_FULL_TARGET_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_TARGET_IMAGE_NAME):v$(BUILD_VERSION).$(BUILD_COUNT))
	@echo "Running $(DOCKER_FULL_TARGET_IMAGE_NAME)"
	docker run --platform $(DOCKER_PLATFORM) --rm -it \
		-v /etc/localtime:/etc/localtime:ro \
		$(DOCKER_FULL_TARGET_IMAGE_NAME)

# -------------------------------------------------------------------------------------------------------
#  Package Extraction
# -------------------------------------------------------------------------------------------------------
docker-artifact-build:
	$(eval DOCKER_FULL_BASE_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_BASE_IMAGE_NAME):$(DOCKER_BASE_IMAGE_TAG)-$(DOCKER_BASE_IMAGE_VERSION))
	$(eval DOCKER_FULL_TARGET_IMAGE_NAME=$(DOCKER_USER)/$(DOCKER_TARGET_IMAGE_NAME):v$(BUILD_VERSION).$(BUILD_COUNT))
	@echo "Extracting artifact from $(DOCKER_FULL_TARGET_IMAGE_NAME) to ./pkgs/"
	DOCKER_BUILDKIT=1 docker build --platform $(DOCKER_PLATFORM) --file Dockerfile \
		$(NOCACHE) \
		--build-arg DOCKER_FULL_BASE_IMAGE_NAME="$(DOCKER_FULL_BASE_IMAGE_NAME)" \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_COUNT=$(BUILD_COUNT) \
		--build-arg BUILD_TAG=$(BUILD_TAG) \
		--tag $(DOCKER_FULL_TARGET_IMAGE_NAME) \
		--target artifact --output type=local,dest=./pkgs/ .

update-dependencies-clevis:
	curl -s https://api.github.com/repos/greycubesgav/slackbuild-clevis/releases/latest \
	| grep "browser_download_url.*unraid-v*" \
	| cut -d '"' -f 4 \
	| xargs -n1 wget -P src/network.disk.unlock/usr/local/emhttp/plugins/network.disk.unlock/pkgs/

update-dependencies-jose:
	curl -s https://api.github.com/repos/greycubesgav/slackbuild-jose/releases/latest \
	| grep "browser_download_url.*unraid-v*" \
	| cut -d '"' -f 4 \
	| xargs -n1 wget -P src/network.disk.unlock/usr/local/emhttp/plugins/network.disk.unlock/pkgs/

update-dependencies: update-dependencies-clevis update-dependencies-jose