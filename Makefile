.DEFAULT_GOAL := help

images = camus:prod camus:latest camus:test-server camus:test-client camus:dev
containers = camus-dev

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: build-prod build-test-server build-dev  ## Build all Docker images, including for production, testing, and development

.PHONY: build-prod
build-prod:  ## Build Docker image for production
	docker build --target prod -t camus:prod -t camus:latest .

.PHONY: build-test-server
build-test-server:  ## Build Docker image for testing the server
	docker build --target test-server -t camus:test-server -t camus:latest .

.PHONY: build-dev
build-dev:  ## Build Docker image for development environment
	docker build --target dev -t camus:dev .

.PHONY: test
test: test-server test-client  ## Run all tests, both server-side and client-side

.PHONY: test-server
test-server:  ## Run server tests
	@docker run --rm -it \
        --mount type=bind,source="$(CURDIR)",target="/opt/camus"\
        -e QUART_APP=/opt/camus/app.py \
        -e QUART_ENV=development \
		camus:test-server \
        /bin/bash -c "pip install -e /opt/camus && python -m pytest /opt/camus"

.PHONY: test-client
test-client: clean-containers serve  ## Run client tests
	@docker run --rm -it \
        --mount type=bind,source="$(CURDIR)/test",target="/e2e" \
		--net host \
		-w /e2e \
		cypress/included:4.5.0

.PHONY: serve
serve: clean-containers  ## Run development server
	@docker run --rm -d \
        --name camus-dev \
        --mount type=bind,source="$(CURDIR)",target="/opt/camus"\
        -e QUART_APP=/opt/camus/app.py \
        -e QUART_ENV=development \
        -p 5000:5000 \
        camus:dev \
        /usr/local/bin/quart run --host 0.0.0.0

.PHONY: shell
shell:  ## Run development environment shell
	@docker run --rm -it \
        --mount type=bind,source="$(CURDIR)",target="/opt/camus"\
        -w /opt/camus \
        -e QUART_APP=/opt/camus/app.py \
        -e QUART_ENV=development \
		camus:dev \
        /bin/bash

.PHONY: clean
clean: clean-containers clean-images  ## Remove Docker containers and images

.PHONY: clean-containers
clean-containers:  ## Remove Docker containers
	@docker stop $(containers) 2>/dev/null || true
	@docker container rm $(containers) 2>/dev/null || true

.PHONY: clean-images
clean-images:  ## Remove Docker images
	@docker image rm $(images) 2>/dev/null || true
