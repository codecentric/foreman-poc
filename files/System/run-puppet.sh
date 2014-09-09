#!/bin/bash

sudo puppet module install --force puppetlabs-stdlib

sudo puppet apply --debug /home/server/git/foreman-poc/manifests/server.pp

