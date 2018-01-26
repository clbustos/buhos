#!/usr/bin/env bash


cd ~/buhos
killall ruby
rackup config.ru -D -E PRODUCTION
