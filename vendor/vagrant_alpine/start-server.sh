#!/usr/bin/env bash


cd ~/buhos
killall ruby
bundle exec rackup config.ru -D -E PRODUCTION
