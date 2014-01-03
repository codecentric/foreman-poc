#!/bin/bash

# architecture
exec { "hammer architecture":
	command	=> "hammer architecture create --name x86_64",
	require	=> File["/var/log/foreman/hammer.log"],
}

# domain
exec { "hammer domain":
	command	=> "hammer domain create --name \"local.cloud\" --description \"Base cloud domain\" hammer domain update --id 1 --dns-id 1",
	require	=> Exec['hammer architecture'],
}

# os
exec { "hammer os":
	command	=> "hammer os create --name Ubuntu --major 12 --minor 04 --family Debian --release-name precise --architecture-ids 1 --ptable-ids 2 --medium-ids 3",
	require	=> Exec['hammer domain'],
}

# templates
exec { "hammer template 6":
	command => "hammer template update --id 6 --operatingsystem-ids 1"
	require	=> Exec['hammer os'],
}
exec { "hammer template 7":
	command => "hammer template update --id 7 --operatingsystem-ids 1"
	require	=> Exec['hammer template 6'],
}
exec { "hammer template 2":
	command => "hammer hammer template update --id 2 --operatingsystem-ids 1"
	require	=> Exec['hammer template 7'],
}

# partition table
exec { "hammer partition table":
	command => "hammer partition_table update --id 2 --file /vagrant/hammer/pTable"
	require	=> Exec['hammer template 2'],
}

# generate pxe 

# subnet
exec { "hammer subnet":
	command	=> "hammer subnet create --name main --network 172.16.0.0 --mask 255.255.255.0 --gateway 172.16.0.2 --domain-ids 1 --dhcp-id 1 --tftp-id 1 --dns-id 1"
	require	=> Exec[''],
}

# OpenStack
exec { 
apt-get -y install git rake
cd /tmp/
mkdir openstack
cd openstack
git clone https://github.com/puppetlabs/puppetlabs-openstack
cd puppetlabs-openstack
git checkout stable/havana
sudo cp -R . /etc/puppet/modules/openstack
sudo apt-get install libactiverecord-ruby libsqlite3-ruby sqlite3

file { '/etc/puppet/puppet.conf':
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,
	source	=> "/vagrant/hammer/puppet.conf",

}

# environment

# puppet module: cloud_box

file { '/etc/puppet/module/cloud_box':
	ensure	=> directory,
}

file { "/etc/puppet/module/cloud_box/params.pp":
	ensure	=> present,
	source	=> "/vagrant/cloud_box/params.pp",
	require	=> File["/etc/puppet/module/cloud_box"],
}

file { "/etc/puppet/module/cloud_box/all_in_one.pp":
	ensure	=> present,
	source	=> "/vagrant/cloud_box/all_in_one.pp",
	require	=> File["/etc/puppet/module/cloud_box"],
}

file { "/etc/puppet/module/cloud_box/controller.pp":
	ensure	=> present,
	source	=> "/vagrant/cloud_box/controller.pp",
	require	=> File["/etc/puppet/module/cloud_box"],
}

file { "/etc/puppet/module/cloud_box/compute.pp":
	ensure	=> present,
	source	=> "/vagrant/cloud_box/compute.pp",
	require	=> File["/etc/puppet/module/cloud_box"],
}

# host


