#!/usr/bin/env bash

 source $HOME/.rvm/scripts/rvm

cd ~/buhos
killall ruby
rackup config.ru -D -E PRODUCTION
