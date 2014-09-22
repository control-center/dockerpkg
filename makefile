# Copyright (C) 2014 Zenoss, Inc
#
# dockerpkg is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# dockerpkg is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar. If not, see <http://www.gnu.org/licenses/>.

## setup all environment stuff
URL           = https://github.com/control-center/dockerpkg
FULL_NAME     = $(shell basename $(URL))
VERSION      := $(shell cat ./VERSION)
DATE         := $(shell date -u)
GIT_COMMIT   ?= $(shell ./hack/gitstatus.sh)
GIT_BRANCH   ?= $(shell git rev-parse --abbrev-ref HEAD)
# jenkins default, jenkins-${JOB_NAME}-${BUILD_NUMBER}
BUILD_TAG    ?= 0
LDFLAGS       = -ldflags "-X main.Version $(VERSION) -X main.Gitcommit '$(GIT_COMMIT)' -X main.Gitbranch '$(GIT_BRANCH)' -X main.Date '$(DATE)' -X main.Buildtag '$(BUILD_TAG)'"

MAINTAINER    = dev@zenoss.com
# https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/#license-specification
DEB_LICENSE   = "GPL-2.0"
# https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing
RPM_LICENSE   = "GPLv2"
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

$(PKGROOT)$(DOCKER_BIN_DIR)/nsenter:
	cd /tmp; \
	wget https://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.bz2; \
	bzip2 -d -c /tmp/util-linux-2.24.tar.bz2 | tar xvf -; \
	cd util-linux-2.24/; \
	./configure --without-ncurses --prefix=/usr/local/util-linux; \
	make; \
	make install; \
	mkdir -p $(PKGROOT)$(DOCKER_BIN_DIR)
	cp -p /usr/local/util-linux/bin/nsenter $(PKGROOT)$(DOCKER_BIN_DIR)

stage_pkg: $(FULL_NAME) $(PKGROOT)$(DOCKER_BIN_DIR)/nsenter
	mkdir -p $(PKGROOT)
	cp -rv $(FULL_NAME)/* $(PKGROOT)/
	mkdir -p $(PKGROOT)$(DOCKER_BIN_DIR)
	wget https://get.docker.io/builds/Linux/x86_64/docker-1.2.0 -O $(PKGROOT)$(DOCKER_BIN_DIR)/$(DOCKER_BIN)
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
		--before-install $(PWD)/$(RPM_SCRIPTS_PATH)/$(PREINSTALL) \
		--after-install $(PWD)/$(RPM_SCRIPTS_PATH)/$(POSTINSTALL) \
		--before-remove $(PWD)/$(RPM_SCRIPTS_PATH)/$(PREUNINSTALL) \
		--after-remove $(PWD)/$(RPM_SCRIPTS_PATH)/$(POSTUNINSTALL) \
		-n $(ACTUAL_PKG_NAME) \
		-f \
		-p /tmp \
		--provides 'docker = 1.2.0' \
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


