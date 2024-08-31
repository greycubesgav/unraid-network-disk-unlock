DOCKER_USER=greycubesgav
DOCKER_IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel`)
DOCKER_IMAGE_VERSION := $(shell grep '<!ENTITY version' network.disk.unlock.plg | sed -n 's/.*[[:space:]]*"\(.*\)".*/\1/p')
DOCKER_PLATFORM=linux/amd64

docker-image-clean:
	docker image rm $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)

docker-image-build:
	docker build --build-arg PLG_VERSION=$(DOCKER_IMAGE_VERSION) --platform $(DOCKER_PLATFORM) --file Dockerfile --tag $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION) .

docker-image-run:
	docker run --platform $(DOCKER_PLATFORM) --rm -it $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)

docker-artifact-build:
	DOCKER_BUILDKIT=1 docker build \
	--build-arg PLG_VERSION=$(DOCKER_IMAGE_VERSION) \
	--platform $(DOCKER_PLATFORM) --file Dockerfile \
	--tag $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION) \
	--target artifact --output type=local,dest=./pkgs/ .

plugin-fix-hashes:
	./update_plg.sh
