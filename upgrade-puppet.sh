#!/bin/bash

wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i puppetlabs-release-precise.deb
sudo apt-get update
#sudo apt-get install --yes puppet=3.3.2-1puppetlabs1
sudo apt-get install --yes puppet

