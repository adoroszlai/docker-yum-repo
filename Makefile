DOCKER_REPO := copy-yum-repo
TRAVIS_BRANCH ?= master
TAG ?= $(subst master,latest,$(TRAVIS_BRANCH))

build:
	docker build --no-cache -t $(DOCKER_USERNAME)/$(DOCKER_REPO):build .

deploy:
	docker tag $(DOCKER_USERNAME)/$(DOCKER_REPO):build $(DOCKER_USERNAME)/$(DOCKER_REPO):$(TAG)
	docker push $(DOCKER_USERNAME)/$(DOCKER_REPO):$(TAG)
