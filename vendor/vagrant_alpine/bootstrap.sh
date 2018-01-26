#!/usr/bin/env bash

killall apk

apk update
apk upgrade
apk --update add --virtual \
        build-dependencies \
        ruby-dev \
        build-base \
        ruby \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        mariadb-dev \
        sqlite-dev \
        ruby-json \
        ruby-bigdecimal \
        ruby-etc


#adduser vagrant staff

if [ ! -L /home/vagrant/buhos ]
then
	cp -r /vagrant_data /home/vagrant/buhos
	chown -R vagrant /home/vagrant/buhos
	rm -f /home/vagrant/buhos/log/*.log
fi