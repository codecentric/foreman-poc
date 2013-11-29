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


file { "/etc/dhcp/dhcpd.conf":
	ensure	=> present,
	source	=> "/vagrant/files/dhcpd.conf",
	owner	=> root,
	group	=> root,
	mode	=> 644,
}

file { "/etc/dhcp/dhcpd.pools":
	ensure	=> present,
	source	=> "/vagrant/files/dhcpd.pools",
	owner	=> root,
	group	=> root,
	mode	=> 644,
}

file { "/etc/dhcp/dhcpd.hosts":
	ensure	=> present,
	source	=> "/vagrant/files/dhcpd.hosts",
	owner	=> root,
	group	=> root,
	mode	=> 644,
}



# options for foreman-installer

file { "/usr/share/foreman-installer/config/answers.yaml":
	ensure	=> present,
	source	=> "/vagrant/files/answers.yaml",
}

## installation foreman
#exec { 'foreman-installer':
#	command	=> "/usr/bin/foreman-installer",
#	require	=> Package["foreman-installer"]
#}

