#!/bin/bash

hammer architecture create --name x86_64

hammer domain create --name "local.cloud" --description "Base cloud domain"

proxy_id=$(hammer proxy list | grep "server.local.cloud" | cut -c 1)
hammer domain update --name local.cloud --dns-id $proxy_id

hammer medium create --name 'Local Mirror' --path http://172.16.0.2:3142/apt-cacher/ubuntu

architecture_id=$(hammer architecture list | grep "x86_64" | cut -c 1)
ptable_id=$(hammer partition_table list | grep "Ubuntu default" | cut -c 1)
medium_id=$(hammer medium list | grep "Local Mirror" | cut -c 1)
hammer os create --name Ubuntu --major 12 --minor 10 --family Debian --release-name quantal --architecture-ids $architecture_id --ptable-ids $ptable_id --medium-ids $medium_id

os_id=$(hammer os list | grep "Ubuntu" | cut -c 1)
template_id_default=$(hammer template list | grep "Preseed Default" | grep "provision" | cut -c 1)
template_id_finish=$(hammer template list | grep "Preseed Default Finish" | cut -c 1)
template_id_pxelinux=$(hammer template list | grep "Preseed default PXElinux" | cut -c 1)
hammer template update --id $template_id_default --operatingsystem-ids $os_id
hammer template update --id $template_id_finish --operatingsystem-ids $os_id
hammer template update --id $template_id_pxelinux --operatingsystem-ids $os_id

hammer partition_table update --id $ptable_id --file /home/ccka/foreman-poc/hammer/pTable

domain_id=$(hammer domain list | grep "local.cloud" | cut -c 1)
hammer subnet create --name main --network 172.16.0.0 --mask 255.255.255.0 --gateway 172.16.0.2 --domain-ids $domain_id --dhcp-id $proxy_id --tftp-id $proxy_id --dns-id $proxy_id

hammer environment create --name cloudbox

