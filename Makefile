export GO111MODULE=on

ifndef DOCKER_REGISTRY
DOCKER_REGISTRY := ullascl/
endif

ifndef TAG
TAG := $(shell git rev-parse HEAD)
endif

ENV_BINARY=\
	$(ENV)/synapse-service-build\

.PHONY: build-image
build-image:
	docker build -f Dockerfile -t ullascl/gateway-sidecar-amd64:1.0.0\
		--build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` \
		--build-arg ACCESS_TOKEN_USR=${GITHUB_USERNAME} \
		--build-arg ACCESS_TOKEN_PWD=${GITHUB_TOKEN} \
		.
	docker push ${DOCKER_REGISTRY}/gateway-sidecar-amd64:${TAG}
	docker logout ${DOCKER_REGISTRY}

