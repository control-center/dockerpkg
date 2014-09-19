FROM zenoss/centos:centos7
MAINTAINER Zenoss, Inc <dev@zenoss.com>	

RUN yum update -y

# build dependencies
RUN	yum install -y rpm-build wget ruby-devel gcc make git

# Install fpm
RUN gem install fpm

