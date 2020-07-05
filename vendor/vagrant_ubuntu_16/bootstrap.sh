#!/usr/bin/env bash



apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

killall apt-get
rm /var/lib/apt/lists/lock

apt-get update
apt-get upgrade -y

apt-get install -y \
  cloc \
  gdal-bin \
  gdebi-core \
  git \
  libcurl4-openssl-dev \
  libgdal-dev \
  libproj-dev \
  libxml2-dev \
  ghostscript \
  imagemagick \
  xpdf \
  curl
  libcurl4-openssl-dev

apt-get install -y build-essential \
    libmysqlclient-dev \
    libsqlite3-dev

adduser vagrant staff

#git clone

if [ ! -L /home/vagrant/buhos ]
then
    git clone /vagrant_data /home/vagrant/buhos
fi

chown -R vagrant /home/vagrant/buhos
rm -f /home/vagrant/buhos/log/*.log
cd /home/vagrant/buhos
git pull origin master
