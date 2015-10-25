#!/bin/bash

# Read params from conf file (emails, passwords, etc.)
if [ ! -f params.conf ]; then
    source ./params.conf
fi


# EXTRA REPOSITORIES

# Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'


# PACKAGES INSTALLATION

# Read packages list from file (one per line)
PACKAGES_LIST=$(cat packages.list | xargs)

# Setup default answers for questions asked during install
echo "mysql-server mysql-server/root_password $MYSQL_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again $MYSQL_PASSWORD" | sudo debconf-set-selections

# Install Ubuntu packages
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install \
    vim \
    git \
    git-extras \
    synaptic \
    php5 \
    mysql-server \
    mysql-client \
    apache2 \
    libapache2-mpm-itk \
    mysql-client \
    mysql-server \
    postgresql-client \
    postgresql \
    sqlite3 \
    php5 \
    php5-curl \
    php5-gd \
    php5-mysql \
    php5-pgsql \
    php5-sqlite \
    php5-xdebug \
    php-pear \
    phpmyadmin \
    phppgadmin \
    curl \
    openjdk-8-jre \
    sqlitebrowser \
    faenza-icon-theme \
    unity-tweak-tool \
    jq \
    google-chrome-stable \
    vlc \
    cmake \
    python-dev \
    ;

# Remove some unnecessary packages
sudo apt-get -y remove \
    unity-lens-music \
    unity-lens-photos \
    unity-lens-shopping \
    unity-lens-video \
    ;

# Cleanup
sudo apt-get clean


# NON PACKAGED SOFTWARE

# NodeJs
NODE_VERSION=$(curl -sG https://nodejs.org/dist/index.json | jq -r ".[0].version")
wget -O /tmp/nodejs.tar.gz "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.gz"
sudo tar xzf /tmp/nodejs.tar.gz -C /opt/
sudo ln -s /opt/node-$NODE_VERSION-linux-x64 /opt/node
sudo ln -s /opt/node/bin/* /usr/local/bin/

# Install PHP Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Add composer bin folder to PATH
printf "\n# Composer bin dir\nexport PATH=\"\$HOME/.composer/vendor/bin:\$PATH\"\n" >> ~/.bashrc

# Install Drush
sudo composer global require drush/drush:7.*


# OTHER STUFF

# Configure some bash aliases
echo "alias cp='cp -i'" >> ~/.bash_aliases
echo "alias mv='mv -i'" >> ~/.bash_aliases
echo "alias rm='rm -i'" >> ~/.bash_aliases

# Generate SSH keys
ssh-keygen -t rsa -b 4096 -C "$SSHKEY_EMAIL" -N "$SSHKEY_PASSWORD" -f ~/.ssh/id_rsa

# Git user info
git config --global user.email "gedvan@gmail.com"
git config --global user.name "Gedvan Dias"

# Some desktop confs
dconf write /com/canonical/indicator/datetime/show-date true
dconf write /com/canonical/indicator/datetime/show-day true
dconf write /com/canonical/unity/lenses/remote-content-search '"none"'

# Faenza icon theme
gsettings set org.gnome.desktop.interface icon-theme 'Faenza-Dark'


