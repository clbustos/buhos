#!/usr/bin/env bash

 source $HOME/.rvm/scripts/rvm

cd ~/buhos
killall ruby
bundle exec rackup config.ru -D -E PRODUCTION
