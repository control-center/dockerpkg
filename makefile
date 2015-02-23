# Copyright (C) 2014 Zenoss, Inc

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## setup all environment stuff
URL           = https://github.com/control-center/dockerpkg
FULL_NAME     = $(shell basename $(URL))
VERSION      := $(shell cat ./VERSION)
ITERATION    := 1
DATE         := $(shell date -u)
GIT_COMMIT   ?= $(shell ./hack/gitstatus.sh)
GIT_BRANCH   ?= $(shell git rev-parse --abbrev-ref HEAD)
# jenkins default, jenkins-${JOB_NAME}-${BUILD_NUMBER}
BUILD_TAG    ?= 0
LDFLAGS       = -ldflags "-X main.Version $(VERSION) -X main.Gitcommit '$(GIT_COMMIT)' -X main.Gitbranch '$(GIT_BRANCH)' -X main.Date '$(DATE)' -X main.Buildtag '$(BUILD_TAG)'"

MAINTAINER    = dev@zenoss.com
# https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/#license-specification
DEB_LICENSE   = Apache-2
# https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing
RPM_LICENSE   = "ASL 2.0"
VENDOR        = Zenoss
PKGROOT       = /tmp/$(FULL_NAME)-pkgroot-$(GIT_COMMIT)
DUID         ?= $(shell id -u)
DGID         ?= $(shell id -g)
DESCRIPTION  := A thin install wrapper for the latest version of Docker
DOCKER_FILES ?= $(shell find $(FULL_NAME)/)
FULL_PATH     = $(shell echo $(URL) | sed 's|https:/||')
DOCKER_WDIR   = /workDir
ACTUAL_PKG_NAME = zenoss-docker
PWD				?= $(shell pwd)

DOCKER_BIN_DIR		= /usr/bin
DOCKER_BIN          = docker
RPM_SCRIPTS_PATH	= rpm
PREINSTALL    		= preinstall
POSTINSTALL	  		= postinstall
PREUNINSTALL  		= preuninstall
POSTUNINSTALL 		= postuninstall


## generic workhorse targets
$(FULL_NAME): VERSION hack/* makefile $(DOCKER_FILES)
	# This won't actually build out any files, just make sure ownership is OK
	chown -R $(DUID):$(DGID) $(FULL_NAME)

docker-tgz: $(FULL_NAME)-build
	docker run --rm -v `pwd`:$(DOCKER_WDIR) -w $(DOCKER_WDIR) -e DUID=$(DUID) -e DGID=$(DGID) zenoss/$(FULL_NAME)-build:$(VERSION) make tgz

docker-deb: $(FULL_NAME)-build
	docker run --rm -v `pwd`:$(DOCKER_WDIR) -w $(DOCKER_WDIR) -e DUID=$(DUID) -e DGID=$(DGID) zenoss/$(FULL_NAME)-build:$(VERSION) make deb

docker-rpm: $(FULL_NAME)-build
	docker run --rm -v `pwd`:$(DOCKER_WDIR) -w $(DOCKER_WDIR) -e DUID=$(DUID) -e DGID=$(DGID) zenoss/$(FULL_NAME)-build:$(VERSION) make rpm

# actual work
.PHONY: $(FULL_NAME)-build
$(FULL_NAME)-build:
	docker build -t zenoss/$(FULL_NAME)-build:$(VERSION) hack

stage_pkg: $(FULL_NAME)
	mkdir -p $(PKGROOT)
	cp -rv $(FULL_NAME)/* $(PKGROOT)/
	mkdir -p $(PKGROOT)$(DOCKER_BIN_DIR)
	wget https://get.docker.io/builds/Linux/x86_64/docker-$(VERSION) -O $(PKGROOT)$(DOCKER_BIN_DIR)/$(DOCKER_BIN)
	chmod +x $(PKGROOT)$(DOCKER_BIN_DIR)/$(DOCKER_BIN)

tgz: stage_pkg
	tar cvfz /tmp/$(FULL_NAME)-$(GIT_COMMIT).tgz -C $(PKGROOT)/ .
	chown $(DUID):$(DGID) /tmp/$(FULL_NAME)-$(GIT_COMMIT).tgz
	mv /tmp/$(FULL_NAME)-$(GIT_COMMIT).tgz .

deb: 
	# Use get.docker.io

rpm: stage_pkg
	fpm \
		-v $(VERSION) \
		--iteration $(ITERATION) \
		-s dir \
		-t rpm \
		-C $(PKGROOT) \
		-m $(MAINTAINER) \
		--description "$(DESCRIPTION)" \
		--rpm-user root \
		--rpm-group root \
		--license $(RPM_LICENSE) \
		--vendor $(VENDOR) \
		--url $(URL) \
		-a x86_64 \
		-d "iptables >= 1.4" \
		-d "git >= 1.7" \
		-d "procps" \
		-d "xz >= 4.9" \
		-d "dnsmasq" \
		--before-install $(PWD)/$(RPM_SCRIPTS_PATH)/$(PREINSTALL) \
		--after-install $(PWD)/$(RPM_SCRIPTS_PATH)/$(POSTINSTALL) \
		--before-remove $(PWD)/$(RPM_SCRIPTS_PATH)/$(PREUNINSTALL) \
		--after-remove $(PWD)/$(RPM_SCRIPTS_PATH)/$(POSTUNINSTALL) \
		-n $(ACTUAL_PKG_NAME) \
		-f \
		-p /tmp \
		--provides 'docker = $(VERSION)' \
		--config-files /etc/sysconfig/docker \
		.
	chown $(DUID):$(DGID) /tmp/*.rpm
	cp -p /tmp/*.rpm .

clean:
	rm -f *.deb
	rm -f *.rpm
	rm -f *.tgz
	rm -fr docker/
	rm -fr /tmp/$(FULL_NAME)-pkgroot-*
	rm -fr /tmp/docker


