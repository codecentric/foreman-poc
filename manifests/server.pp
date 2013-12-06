# aptkey
define aptkey($ensure, $apt_key_url = 'http://deb.theforeman.org') {
  case $ensure {
    'present': {
      exec { "apt-key present $name":
	command => "/usr/bin/wget -q $apt_key_url/$name -O -|/usr/bin/apt-key add -",
	unless  => "/usr/bin/apt-key list|/bin/grep -c $name",
      }
    }
    'absent': {
      exec { "apt-key absent $name":
	command => "/usr/bin/apt-key del $name",
	onlyif  => "/usr/bin/apt-key list|/bin/grep -c $name",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for apt::key"
    }
  }
}

# apt sources
file {'foremanlist':
	path	=> '/etc/apt/sources.list.d/foreman.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ precise 1.3'
}

file {'smartproxylist':
	path	=> '/etc/apt/sources.list.d/smartproxy.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ precise stable'
}

aptkey { 'foreman.asc':
	ensure	=> present
}

# update and source installation
exec { "apt-update":
	command	=> "/usr/bin/apt-get update",
	require	=> Aptkey['foreman.asc'],
}

package { "foreman-installer":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

# seperate bind installation necessary for configuration
package { "bind9":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

# DHCP configuration
file { "/etc/dhcp/dhcpd.conf":
	ensure	=> present,
	source	=> "/vagrant/files/DHCP/dhcpd.conf",
	owner	=> root,
	group	=> root,
	mode	=> 644,
}

#file { "/etc/dhcp/dhcpd.pools":
#	ensure	=> present,
#	source	=> "/vagrant/files/DHCP/dhcpd.pools",
#	owner	=> root,
#	group	=> root,
#	mode	=> 644,
#}

file { "/etc/dhcp/dhcpd.hosts":
	ensure	=> present,
	source	=> "/vagrant/files/DHCP/dhcpd.hosts",
	owner	=> root,
	group	=> root,
	mode	=> 644,
}

# placing the keyfile
file { "/etc/bind/DHCP_UPDATER":
	ensure	=> present,
	source	=> "/vagrant/files/DHCP/DHCP_UPDATER",
	owner	=> root,
	group	=> bind,
	mode	=> 640,
	require	=> Package["bind9"],
}

# TFTP

# create the TFTP-root directory and set the permissions
file { '/var/lib/tftpboot':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
}

# create pxelinux.cfg directory and set the permissions
file { '/var/lib/tftpboot/pxelinux.cfg':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
}

# netboot image for Ubunu 12.04
file { '/var/lib/tftpboot/ubuntu-12.04':
	ensure	=> directory,
	recurse	=> true,
	purge	=> true,
	force	=> true,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/ubuntu-12.04",
}

# config: list of available boot image
file { '/var/lib/tftpboot/pxelinux.cfg/default':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/default",
}

# boot menu text
file { '/var/lib/tftpboot/boot.txt':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/boot.txt",
}


# options for foreman-installer

file { "/usr/share/foreman-installer/config/answers.yaml":
	ensure	=> present,
	source	=> "/vagrant/files/answers.yaml",
	owner	=> root,
	group	=> root,
	require	=> [ Package["foreman-installer"], File['/etc/dhcp/dhcpd.conf']]
}

# installation foreman
exec { 'foreman-installer':
	command	=> "/usr/bin/foreman-installer",
	require => [ Package["bind9"], Package["foreman-installer"]],
}


# adding user 'foreman-proxy' to group 'bind', as this users needs to read the keyfile
user { "foreman-proxy":
	ensure	=> present,
	groups	=> ['bind'], 
	require => Exec["foreman-installer"],
}
