# Check if variable has been defined, otherwise print custom error message
check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

RELEASE_BRANCH=master
VERSION = $(shell git describe --always --tag)
REPOSITORY = quay.io/poka/docker-haraka
THIS_DIR:=$(shell pwd)

version:
	@echo $(VERSION)

build:
	docker build --pull -t $(REPOSITORY):$(VERSION) .

push:
	docker push $(REPOSITORY):$(VERSION)

generate-changelog:
	$(call check_defined, FUTURE_RELEASE, Ex: make generate-changelog FUTURE_RELEASE=v1.0.0)
	docker pull prooph/github-changelog-generator
	docker run -e CHANGELOG_GITHUB_TOKEN=$(CHANGELOG_GITHUB_TOKEN) -it --rm -v $(THIS_DIR):/app prooph/github-changelog-generator --release-branch=master --no-issues --future-release=$(FUTURE_RELEASE)
