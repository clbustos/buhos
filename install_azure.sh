#!/bin/bash 

# This instructions should be run on Azure Cloud Shell, using bash
# > az group create --name buhosResource --location eastus
# > az vm create --resource-group buhosResource --name vmBuhos --image UbuntuLTS --admin-username $USER --generate-ssh-keys
# > az vm open-port --port 9292 --resource-group buhosResource --name vmBuhos
# Check the public IP and use it on next line
# > ssh $USER@[publicIp]


sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
  cloc \
  curl \
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
  build-essential \
  libmysqlclient-dev \
  libsqlite3-dev \
  mysql-server \
  git

git clone https://github.com/clbustos/buhos.git

# Install RVM



gpg --keyserver hkp://keys.gnupg.net \
      --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s $1

source "${HOME}/.rvm/scripts/rvm"
# Install ruby and dependences 
rvm install ruby-2.6
gem install bundler
cd buhos
mkdir log
bundle install

# This creates db and user for mysql

echo "CREATE DATABASE buhos;" | sudo mysql -u root 
echo "CREATE USER buhos_user@localhost IDENTIFIED BY 'bhbhbh';" | sudo mysql -u root
echo "GRANT ALL PRIVILEGES ON buhos.* TO buhos_user@localhost;" | sudo  mysql -u root
echo "FLUSH PRIVILEGES;" | sudo mysql -u root

# This create the connection to database directly on .env file

echo "DATABASE_URL=mysql2://buhos_user:bhbhbh@localhost:3306/buhos" > .env
# Start the installer

rackup -E production
# Use ctrl+c to stop the daemon after installation

rackup -E production & # To daemonize on user dir.

