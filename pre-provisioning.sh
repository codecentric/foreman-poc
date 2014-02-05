#!/bin/bash

sudo apt-get purge ruby ruby-sinatra
sudo apt-get autoremove
sudo apt-get install ruby1.9.1-dev
cd /usr/lib/ruby/vendor_ruby/
sudo gem install sinatra

wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i puppetlabs-release-precise.deb
sudo apt-get update
#sudo apt-get install --yes puppet=3.3.2-1puppetlabs1
sudo apt-get install --yes puppet

sudo puppet module install  puppetlabs-stdlib
