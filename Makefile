# Check if variable has been defined, otherwise print custom error message
check_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

RELEASE_BRANCH=master
GIT_DESCRIBE_TAG = $(shell git describe --always --tag)
VERSION = $(GIT_DESCRIBE_TAG)
CI_ACCOUNT_ID = $(shell aws ssm get-parameter --name organization.accounts.ci.id --query "Parameter.Value" --output text)
ECR_REPOSITORY = $(CI_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com/docker-haraka
THIS_DIR:=$(shell pwd)

version:
	@echo $(VERSION)

login_to_ecr:
	@$(shell aws ecr get-login --no-include-email --registry-ids $(CI_ACCOUNT_ID) --region us-east-1)

build:
	@docker build -t $(ECR_REPOSITORY):$(VERSION) .

push: login_to_ecr
	@docker push $(ECR_REPOSITORY):$(VERSION)

generate-changelog:
	$(call check_defined, FUTURE_RELEASE, Ex: make generate-changelog FUTURE_RELEASE=v1.0.0)
	@docker pull pokainc/github-changelog-generator
	@docker run -e CHANGELOG_GITHUB_TOKEN=$(CHANGELOG_GITHUB_TOKEN) -it --rm -v $(THIS_DIR):/app pokainc/github-changelog-generator --future-release=$(FUTURE_RELEASE)
