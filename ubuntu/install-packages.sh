#!/bin/bash

PACKAGES_LIST=$(cat packages.list | xargs)
MYSQL_PASSWORD=""

read -s -p "MySQL Password: " MYSQL_PASSWORD

sudo apt-get -y update
sudo apt-get -y dist-upgrade

echo "mysql-server mysql-server/root_password $MYSQL_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again $MYSQL_PASSWORD" | sudo debconf-set-selections

sudo apt-get -y install $PACKAGES_LIST
