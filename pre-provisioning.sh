#!/bin/bash

#echo "deb http://deb.theforeman.org/ wheezy stable" | sudo tee -a /etc/apt/sources.list
echo -e "auto eth0 \n iface eth0 inet static \n       address 172.16.0.2 \n       netmask 255.255.255.0" | sudo tee -a /etc/network/interfaces
#sudo apt-get update
#sudo apt-get install ruby-sinatra=1.3.6-1
#sudo apt-get purge ruby ruby-sinatra
#sudo apt-get autoremove
#sudo apt-get install ruby1.9.1-dev
#cd /usr/lib/ruby/vendor_ruby/
#sudo gem install sinatra
#cd

wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i puppetlabs-release-precise.deb
sudo apt-get update
#sudo apt-get install --yes puppet=3.3.2-1puppetlabs1
sudo apt-get install --yes puppet

sudo puppet module install  puppetlabs-stdlib

rm puppetlabs-release-precise.deb
sudo reboot
