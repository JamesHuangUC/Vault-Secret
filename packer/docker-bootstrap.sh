#!/bin/sh
sudo apt -y update
sudo apt -y upgrade

sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce
sudo usermod -aG docker ubuntu

sleep 10
echo 'Cleaning up after bootstrapping...'
sudo apt -y autoremove
sudo apt -y clean
sudo rm -rf /tmp/*
cat /dev/null > ~/.bash_history

docker -v
cat /etc/*release
exit
