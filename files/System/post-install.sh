#!/bin/bash

#cd $HOME
#sudo apt-get install openssh-server git
#mkdir -p git
#cd git
#
#if [ ! -d "$HOME/git/foreman-poc"  ]; then
#	git clone https://github.com/adaman79/foreman-poc.git
#fi
#
#cd foreman-poc
#git checkout bare_metal
#
#sudo cp /vagrant/files/System/interfaces /etc/network/

wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i puppetlabs-release-precise.deb
sudo apt-get update
sudo apt-get install --yes puppet

sudo cp /vagrant/files/System/puppet.conf /etc/puppet/
sudo service puppet restart
sudo puppet module install --force puppetlabs-stdlib

rm puppetlabs-release-precise.deb

#sudo reboot
