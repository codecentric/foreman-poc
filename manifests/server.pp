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

# seperate installations necessary for proper configuration
package { "bind9":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}
package { "isc-dhcp-server":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

# placing the keyfile
file { "/etc/bind/rndc.key":
	ensure	=> present,
	source	=> "/vagrant/files/DHCP/rndc.key",
	owner	=> root,
	group	=> bind,
	mode	=> 640,
	require	=> Package["bind9"],
}

# adding user 'dhcpd' to group 'bind', as this users needs to read the keyfile
user { "dhcpd":
	ensure	=> present,
	groups	=> ['bind'],
	require => [
		Package["isc-dhcp-server"],
		Package["bind9"],
	],
}


# workaround that DHCP can read the keyfile
# replace existing DHCPd-apparmor configuration
service { "apparmor":
    ensure  => "running",
    enable  => "true",
}

file { "/etc/apparmor.d/usr.sbin.dhcpd":
	notify  => Service["apparmor"],
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,
	source	=> "/vagrant/files/DHCP/apparmor_usr.sbin.dhcpd",
	require => Package["isc-dhcp-server"],
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
	require	=> File["/var/lib/tftpboot"],
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
	require	=> File["/var/lib/tftpboot"],
}

# config: list of available boot image
file { '/var/lib/tftpboot/pxelinux.cfg/default':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/default",
	require	=> File["/var/lib/tftpboot/pxelinux.cfg"],
}

# boot menu text
file { '/var/lib/tftpboot/boot.txt':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/vagrant/files/TFTP/boot.txt",
	require	=> File["/var/lib/tftpboot"],
}


# options for foreman-installer

file { "/usr/share/foreman-installer/config/answers.yaml":
	ensure	=> present,
	source	=> "/vagrant/files/answers.yaml",
	owner	=> root,
	group	=> root,
	mode	=> 600,
	require	=> Package["foreman-installer"],
}

# modifying foreman-installer to support DDNS
file { "/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp":
	ensure	=> present,
	source	=> "/vagrant/files/proxydhcp.pp",
	owner	=> root,
	group	=> root,
	mode	=> 644,
	require	=> Package["foreman-installer"],
}


# installation foreman
exec { 'foreman-installer':
	command	=> "/usr/bin/foreman-installer",
	require => [
		Package["bind9"],
		File['/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp'],
		File['/usr/share/foreman-installer/config/answers.yaml'],
		File["/etc/bind/rndc.key"]
	],
}


# adding user 'foreman-proxy' to group 'bind', as this users needs to read the keyfile
user { "foreman-proxy":
	ensure	=> present,
	groups	=> ['bind'], 
	require => Exec["foreman-installer"],
}
