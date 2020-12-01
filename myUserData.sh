#!/bin/bash

git clone https://github.com/jpetazzo/container.training.git
cd container.training/dockercoins/

sudo apt update
sudo apt install docker-compose -y
sudo docker-compose up -d

# install nginx
apt-get update
apt-get -y install nginx

# make sure nginx is started
service nginx start
