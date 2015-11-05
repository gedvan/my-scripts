#!/bin/bash

# PARAMS
# Read params from conf file (emails, passwords, etc.)

if [ ! -f params.conf ]; then
    source ./params.conf
fi

# SUDO
# Allows sudo on this script

SUDOER_LINE="$USER ALL=(ALL) NOPASSWD:$(readlink -f $0)"
SUDOER_FILE="/etc/sudoers.d/$USER"
sudo grep "$SUDOER_LINE" $SUDOER_FILE  > /dev/null 2> /dev/null
if [ $? -ne 0 ]; then
    echo $SUDOER_LINE | sudo tee -a $SUDOER_FILE > /dev/null
    sudo chmod 0400 $SUDOER_FILE
fi

# EXTRA REPOSITORIES

# Google Chrome
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Arc Theme
wget -qO - http://download.opensuse.org/repositories/home:Horst3180/xUbuntu_15.04/Release.key | sudo apt-key add -
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/Horst3180/xUbuntu_15.04/ /' >> /etc/apt/sources.list.d/arc-theme.list"

# PACKAGES INSTALLATION

# Read packages list from file (one per line)
PACKAGES_LIST=$(cat packages.list | xargs)

# Setup default answers for questions asked during install
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD"

# Install Ubuntu packages
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install $PACKAGES_LIST

# Remove some unnecessary packages
#sudo apt-get -y remove ...

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
mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -C "$SSHKEY_EMAIL" -N "$SSHKEY_PASSWORD" -f ~/.ssh/id_rsa

# Git user info
git config --global user.email "gedvan@gmail.com"
git config --global user.name "Gedvan Dias"

# Some desktop confs
dconf write /com/canonical/indicator/datetime/show-date true
dconf write /com/canonical/indicator/datetime/show-day true
dconf write /com/canonical/unity/lenses/remote-content-search '"none"'

# Desktop theme
gsettings set org.gnome.desktop.interface icon-theme 'Faenza-Dark'
gsettings set org.gnome.desktop.wm.preferences theme "Arc-Darker"
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Darker"

# Apache setup
sudo a2enmod rewrite
sudo service apache2 restart

