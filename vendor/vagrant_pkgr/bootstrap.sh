#!/usr/bin/env bash




killall apt-get
rm /var/lib/apt/lists/lock

apt-get update
apt-get upgrade -y

cd /vagrant_data/packages
for i in *.deb
do
  dpkg -i "${i}"
  sudo apt-get -f -y install
  buhos config:set PORT=9292
  buhos scale web=1
done
  
