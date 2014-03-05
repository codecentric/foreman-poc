#!/bin/bash

# Create Architecture (if not alreay there)
if [ -z "$(hammer architecture list | /bin/grep "x86_64")"  ]; then
	hammer architecture create --name x86_64
else
	echo "Already created: Architecture"
fi

# Create Domain (if not alreay there)
if [ -z "$(hammer domain list | /bin/grep "local.cloud")"  ]; then
	hammer domain create --name "local.cloud" --description "Base cloud domain"
else
	echo "Already created: Domain"
fi

# Update Domain with DNS-id
proxy_id=$(hammer proxy list | /bin/grep "server.local.cloud" | /usr/bin/cut -d' ' -f1)
hammer domain update --name local.cloud --dns-id $proxy_id

# Create Installation Medium (if not alreay there)
if [ -z "$(hammer medium list | /bin/grep "Local Mirror")"  ]; then
	hammer medium create --name 'Local Mirror' --path http://172.16.0.2:3142/apt-cacher/ubuntu --os-family Debian
else
	echo "Already created: Installation Medium"
fi

# Create OS (if not alreay there)
ptable_id=$(hammer partition_table list | /bin/grep "Preseed default" | /usr/bin/cut -d' ' -f1)
os_id=$(hammer os list | /bin/grep "Ubuntu" | /usr/bin/cut -d' ' -f1)
if [ -z $os_id  ]; then
	architecture_id=$(hammer architecture list | /bin/grep "x86_64" | /usr/bin/cut -d' ' -f1)
	medium_id=$(hammer medium list | /bin/grep "Local Mirror" | /usr/bin/cut -d' ' -f1)
	hammer os create --name Ubuntu --major 12 --minor 10 --family Debian --release-name quantal --architecture-ids $architecture_id --ptable-ids $ptable_id --medium-ids $medium_id
	os_id=$(hammer os list | /bin/grep "Ubuntu" | /usr/bin/cut -d' ' -f1)
else
	echo "Already created: OS"
fi

# Update Provisioning Templates
template_id_default=$(hammer template list --search "Preseed default" | /bin/grep "Preseed default" | /usr/bin/cut -c 1-22 | /bin/grep "[[:space:]]$" | /usr/bin/cut -d' ' -f1)
template_id_finish=$(hammer template list --search "Preseed default finish" | /bin/grep "Preseed default finish" | /usr/bin/cut -d' ' -f1)
template_id_pxelinux=$(hammer template list --search "Preseed default PXELinux" | /bin/grep "Preseed default PXELinux" | /usr/bin/cut -d' ' -f1)
hammer template update --id $template_id_default --operatingsystem-ids $os_id
hammer template update --id $template_id_finish --operatingsystem-ids $os_id
hammer template update --id $template_id_pxelinux --operatingsystem-ids $os_id

# Update PXELinux global default
template_id_pxelinux_global_default=$(hammer template list --search "PXELinux global default" | /bin/grep "PXELinux global default" | /usr/bin/cut -d' ' -f1)
hammer template update --id $template_id_pxelinux_global_default --file /home/server/git/foreman-poc/hammer/PXELinux_global_default

# Update Preseed Finish
hammer template update --id $template_id_finish --file /home/server/git/foreman-poc/hammer/preseed_default_finish

# Update Puppet.conf
template_id_puppetConf=$(hammer template list --search puppet.conf | /bin/grep puppet.conf | /usr/bin/cut -d' ' -f1)
hammer template update --id $template_id_puppetConf --file /home/server/git/foreman-poc/hammer/puppet.conf

# Update Partition Table
hammer partition_table update --id $ptable_id --file /home/server/git/foreman-poc/hammer/pTable

# Create Subnet (if not alreay there)
if [ -z "$(hammer subnet list | /bin/grep "main")"  ]; then
	domain_id=$(hammer domain list | /bin/grep "local.cloud" | /usr/bin/cut -d' ' -f1)
	hammer subnet create --name main --network 172.16.0.0 --mask 255.255.255.0 --gateway 172.16.0.2 --domain-ids $domain_id --dhcp-id $proxy_id --tftp-id $proxy_id --dns-id $proxy_id
else
	echo "Already created: Subnet"
fi
# Create Environment (if not alreay there)
if [ -z "$(hammer environment list | /bin/grep "cloudbox")"  ]; then
	hammer environment create --name cloudbox
else
	echo "Already created: Environment"
fi

