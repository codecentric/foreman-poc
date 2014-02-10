#!/bin/bash

cd /home/server/
sudo apt-get install openssh-server git
mkdir git
cd git
git clone https://github.com/adaman79/foreman-poc.git
cd foreman-poc
git checkout bare_metal
sudo ./files/System/pre-provisioning.sh

