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
ptable_id=$(hammer partition-table list | /bin/grep "Preseed default" | /usr/bin/cut -d' ' -f1)
os_id=$(hammer os list | /bin/grep "Ubuntu" | /usr/bin/cut -d' ' -f1)
architecture_id=$(hammer architecture list | /bin/grep "x86_64" | /usr/bin/cut -d' ' -f1)
medium_id=$(hammer medium list | /bin/grep "Local Mirror" | /usr/bin/cut -d' ' -f1)
if [ -z $os_id  ]; then
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
hammer template update --id $template_id_pxelinux_global_default --file /vagrant/hammer/PXELinux_global_default

# Update Preseed Finish
hammer template update --id $template_id_finish --file /vagrant/hammer/preseed_default_finish

# Update Puppet.conf
template_id_puppetConf=$(hammer template list --search puppet.conf | /bin/grep puppet.conf | /usr/bin/cut -d' ' -f1)
hammer template update --id $template_id_puppetConf --file /vagrant/hammer/puppet.conf --type snippet

# Update Partition Table
hammer partition-table update --id $ptable_id --file /vagrant/hammer/pTable
domain_id=$(hammer domain list | /bin/grep "local.cloud" | /usr/bin/cut -d' ' -f1)

# Create Subnet (if not alreay there)
if [ -z "$(hammer subnet list | /bin/grep "main")"  ]; then
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

#Create Hostgroup
environment_id_cloudbox=$(hammer environment list --search "cloudbox" | /bin/grep "cloudbox" | /usr/bin/cut -d' ' -f1)
subnet_id_main=$(hammer subnet list --search "main" |  /bin/grep "main" | /usr/bin/cut -d' ' -f1)

hammer hostgroup create --name 'multidisk' --environment-id $environment_id_cloudbox --operatingsystem-id $os_id --architecture-id $architecture_id --medium-id $medium_id --ptable-id $ptable_id --puppet-ca-proxy-id $proxy_id --subnet-id $subnet_id_main --domain-id $domain_id --puppet-proxy-id $proxy_id

hostgroup_id_multidisk=$(hammer hostgroup list --search "multidisk" | /bin/grep "multidisk" | /usr/bin/cut -d' ' -f1)
hammer hostgroup set-parameter --name 'drives' --value '/dev/sdb:/drv/drive01' --hostgroup-id $hostgroup_id_multidisk

#Provisioning Template
# Provisioning Template
#if [ -z "$(hammer template list --search 'Preseed multidisk finish' | /bin/grep 'Preseed multidisk finish')"  ]; then
#        hammer template create --file '/vagrant/hammer/preseed_multidisk_finish' --type 'finish' --name 'Preseed multidisk finish' --operatingsystem-ids $os_id
#else
#        echo "Already created: Provisioning Template 'multidisk'"
#fi
