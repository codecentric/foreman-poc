

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


aptkey { 'foreman.asc':
	ensure	=> present
}

->

	File['prepare_list_foreman'] ->
	File['prepare_list_smartproxy'] ->
	File['prepare_list_plugin'] ->
	Exec['apt-update'] ->
	Package['make'] ->
	Package['openssh-server'] ->
	Package['foreman-installer'] ->
	Package['bind9'] ->
	Exec['teardown-apparmor'] ->
	Package['isc-dhcp-server'] ->
	Package['git'] ->
	Package['gem'] ->
	File['/etc/bind/rndc.key'] ->
	User['dhcpd'] ->
	File_Line['dhclient'] ->
	File['/var/lib/tftpboot'] ->
	File['/var/lib/tftpboot/pxelinux.cfg'] ->
	File['/var/lib/tftpboot/boot'] ->
	File['/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-initrd.gz'] ->
	File['/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-linux'] ->
	Exec['wget initrd.img'] ->
	Exec['wget vmlinuz'] ->
	File['/etc/foreman/foreman-installer-answers.yaml'] ->
	Exec['foreman-installer'] ->
	User['foreman-proxy'] ->
	File['/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-img'] ->
	File['/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-vmlinuz'] ->
	
	File['/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp'] ->

	File['/etc/foreman/settings.yaml'] ->
	Exec['foreman-restart'] ->
	Exec['foreman-cache'] ->
	Package['ruby-dev'] ->
	Package['hammer_cli'] ->
	Package['hammer_cli_foreman'] ->
	File['/etc/hammer'] ->
	File['/etc/hammer/cli_config.yml'] ->
	File['/var/log/foreman/hammer.log'] ->
	Exec['hammer execution'] ->
	Exec['net.ipv4.ip_forward'] ->
	Exec['sysctl'] ->
	Exec['iptables forward'] ->
	Exec['iptables masquerade'] ->
	Package['debconf-utils'] ->
	Exec['preseed'] ->
	Package['iptables-persistent'] ->
	Service['iptables-persistent'] ->
	Service['apache2'] ->
	Package['apt-cacher'] ->
	Service['apt-cacher'] ->
	File['/etc/apt-cacher/apt-cacher.conf'] ->
	Exec['apt-cacher-import'] ->
	File_Line['sudo_rule_v1'] ->
	File_Line['sudo_rule_v2'] ->
	File_Line['sudo_rule_v3'] ->
	File['/usr/share/foreman/bundler.d/plugins.rb'] ->
	File_Line['add-gem-foreman_discovery'] ->
	Exec['bundle-update'] ->
	File_Line['uncomment_environmentpath'] ->
	File_Line['add-cloudbox-1'] ->
	File_Line['add-cloudbox-2'] ->
	File_Line['add-cloudbox-3'] ->
	Exec['restart-puppet'] ->
	Exec['second_foreman-restart']


	
	

# apt sources
file {'prepare_list_foreman':
	path	=> '/etc/apt/sources.list.d/foreman.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ trusty 1.7'
}

file {'prepare_list_smartproxy':
	path	=> '/etc/apt/sources.list.d/smartproxy.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ trusty 1.7'
}

file {'prepare_list_plugin':
        path    => '/etc/apt/sources.list.d/foreman-plugins.list',
        ensure  => present,
        mode    => 0644,
        content => 'deb http://deb.theforeman.org/ plugins 1.7'
}



# update and source installation
exec { "apt-update":
	command	=> "/usr/bin/apt-get update",
}



package { "make":
	ensure	=> "installed",
}

package { "openssh-server":
	ensure	=> "installed",
}

package { "foreman-installer":
	ensure => ['1.7.1-1', installed],
}

# seperate installations necessary for proper configuration
package { "bind9":
	ensure	=> "installed",

}

exec { 'teardown-apparmor':
	command	=> "service apparmor teardown",
	path	=> "/usr/bin/",
}

package { "isc-dhcp-server":
	ensure	=> "installed",	
}

package { "git":
	ensure  => "installed",

}
package { "gem":
	ensure => "installed",
	install_options => [ '--force-yes'],

}

# placing the keyfile
file { "/etc/bind/rndc.key":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/BIND/rndc.key",
	owner	=> root,
	group	=> bind,
	mode	=> 640,
}

# adding user 'dhcpd' to group 'bind', as this users needs to read the keyfile
user { "dhcpd":
	ensure	=> present,
	groups	=> ['bind'],
}

# dhclient fix: prepend DNS-server
file_line { 'dhclient':
	path	=> '/etc/dhcp/dhclient.conf',
	line	=> 'prepend domain-name-servers 172.16.0.2;',
	match	=> "prepend domain-name-servers",
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

# netboot image directory
file { '/var/lib/tftpboot/boot':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	
}

# copy image for Ubuntu 12.10
file { '/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-initrd.gz':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/home/server/git/foreman-poc/files/TFTP/ubuntu12.10/initrd.gz",
	
}

file { '/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-linux':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/home/server/git/foreman-poc/files/TFTP/ubuntu12.10/linux",
	
}

# download discovery images
exec { "wget initrd.img":
       command => "wget http://downloads.theforeman.org/discovery/releases/0.5/foreman-discovery-image-latest.el6.iso-img",
       cwd     => "/var/lib/tftpboot/boot/",
       creates => "/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-img",
       path    => "/usr/bin",
       timeout => 1000,
       
}


exec { "wget vmlinuz":
        command => "wget http://downloads.theforeman.org/discovery/releases/0.5/foreman-discovery-image-latest.el6.iso-vmlinuz",
        cwd     => "/var/lib/tftpboot/boot/",
        creates => "/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-vmlinuz",
        path    => "/usr/bin",
        timeout => 1000,
        
}


# set permissions for discovery images
file { '/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-img':
      ensure  => present,
      owner   => foreman-proxy,
      group   => nogroup,
      mode    => 644,
     
}


file { '/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-vmlinuz':
      ensure  => present,
      owner   => foreman-proxy,
      group   => nogroup,
      mode    => 644,
      
}


# options for foreman-installer
file { "/etc/foreman/foreman-installer-answers.yaml":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/Foreman/answers.yaml",
	owner	=> root,
	group	=> root,
	mode	=> 600,
	
}

# modifying foreman-installer to support DDNS
file { "/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/DHCP/proxydhcp.pp",
	owner	=> root,
	group	=> root,
	mode	=> 644,
	
}



# installation foreman
exec { 'foreman-installer':
	command	=> "/usr/sbin/foreman-installer --foreman-proxy-trusted-hosts=localhost --foreman-admin-password changeme",
	environment => ["HOME=/home/server"],
	timeout => 0,
	
}



# adding user 'foreman-proxy' to group 'bind', as this users needs to read the keyfile
user { "foreman-proxy":
	ensure	=> present,
	groups	=> ['bind'],
}

# foreman settings
file { "/etc/foreman/settings.yaml":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/Foreman/settings.yaml",
	owner	=> root,
	group	=> foreman,
	mode	=> 640,
	
}

exec { "foreman-restart":
	command		=> "touch ~foreman/tmp/restart.txt",
	refreshonly	=> true,
	path		=> "/usr/bin/",
}

exec { "foreman-cache":
	command		=> "/usr/sbin/foreman-rake apipie:cache",
	
}

# ruby-dev
# install ruby-dev package
package { 'ruby-dev':
	ensure		=> installed,
	
}








# install hammer cli
package { 'hammer_cli':
	ensure		=> installed,
	provider	=> "gem",
	
}

# install foreman plugin for hammer
package { 'hammer_cli_foreman':
	ensure	=> installed,
	provider => "gem",
	
}

# set up hammer for foreman
file { '/etc/hammer':
        ensure  => directory,
        owner   => nobody,
        group   => nogroup,
        mode    => 777,
}
# hammer config file
file { "/etc/hammer/cli_config.yml":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/hammer/cli_config.yml",

}

# hammer logging
file { '/var/log/foreman/hammer.log':
	ensure	=> present,
	mode	=> 777,

}

exec { "hammer execution":
	command	=> "/home/server/git/foreman-poc/hammer/hammer.sh",
	path	=> "/usr/local/bin/",

#	user	=> "server",
	environment	=> ["HOME=/home/server"],
}





# uncomment IP forwarding
exec { 'net.ipv4.ip_forward':
	command	=> "/bin/sed -i -e'/#net.ipv4.ip_forward=1/s/^#\\+//' '/etc/sysctl.conf'",
	onlyif	=> "/bin/grep '#net.ipv4.ip_forward=1' '/etc/sysctl.conf' | /bin/grep '^#' | /usr/bin/wc -l",
}

# no restart necessary
exec { 'sysctl':
	command	=> "sysctl -w net.ipv4.ip_forward=1",
	path	=> "/sbin/",

}

# create firewall rules
exec { 'iptables forward':
	command	=> "iptables -P FORWARD ACCEPT",
	path	=> "/sbin",

}
exec { 'iptables masquerade':
	command	=> "iptables --table nat -A POSTROUTING -o eth1 -j MASQUERADE",
	path	=> "/sbin",

}

# preseed iptables-persistent
package{ 'debconf-utils':
	ensure	=> installed,
}

exec { 'preseed':
	command	=> "debconf-set-selections /home/server/git/foreman-poc/files/System/iptables-persistent.seed",
	path	=> "/usr/bin/",

}

# install iptables-persistent
package { 'iptables-persistent':
	ensure	=> installed,
}




# start iptables-persistent
service { "iptables-persistent":
	ensure	=> running,
	}

# Install local ubuntu repository: apt-cacher
service { "apache2":
	ensure  => "running",
	enable  => "true",

}

package { 'apt-cacher':
	ensure	=> installed,

}

service { "apt-cacher":
	ensure  => "running",
	enable  => "true",

}

file { '/etc/apt-cacher/apt-cacher.conf':
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,
	source	=> "/home/server/git/foreman-poc/files/System/apt-cacher.conf",


}


#
#
# OBERHALB: SCHON VERARBEITET
# UNTERHALB: NOCH VERARBEITEN
#
#
#
#
#
















# workaround that DHCP can read the keyfile
# replace existing DHCPd-apparmor configuration
#service { "apparmor":
#    ensure  => "running",
#    enable  => "true",
#}

#file { "/etc/apparmor.d/usr.sbin.dhcpd":
#	notify  => Service["apparmor"],
#	ensure	=> present,
#	owner	=> root,
#	group	=> root,
#	mode	=> 644,
#	source	=> "/home/server/git/foreman-poc/files/DHCP/apparmor_usr.sbin.dhcpd",
#	require => Package["isc-dhcp-server"],
#}













exec {'apt-cacher-import':
	command => "apt-cacher-import.pl -r /var/cache/apt/archives",
	path	=> "/usr/share/apt-cacher/",

}

file_line { 'sudo_rule_v1':
	path	=> '/etc/sudoers',
	line	=> 'Defaults:foreman-proxy !requiretty',
	
}

file_line { 'sudo_rule_v2':
	path	=> '/etc/sudoers',
	line	=> 'foreman-proxy ALL = NOPASSWD: /usr/bin/puppet kick *',
	
}
 
file_line { 'sudo_rule_v3':
	path	=> '/etc/sudoers',
	line	=> 'foreman-proxy ALL = NOPASSWD: /usr/bin/puppet cert *',

}

file { '/usr/share/foreman/bundler.d/plugins.rb':
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,

}

file_line { 'add-gem-foreman_discovery':
	path	=> '/usr/share/foreman/bundler.d/plugins.rb',
	line	=> 'gem \'foreman_discovery\'',

}

exec { 'bundle-update':
       command => "gem install json -v \'1.8.2\'; bundle update",
       cwd     => "/usr/share/foreman",
	   path => ['/usr/bin/', '/bin/', '/sbin/', '/usr/sbin'],
}

file_line { 'uncomment_environmentpath':
	path	=> '/etc/puppet/puppet.conf',
	line	=> '#    environmentpath  = /etc/puppet/environments',
	match	=> '    environmentpath  = /etc/puppet/environments',

}

file_line { 'add-cloudbox-1':
	path	=> '/etc/puppet/puppet.conf',
	line	=> '',

}

file_line { 'add-cloudbox-2':
	path	=> '/etc/puppet/puppet.conf',
	line	=> '[cloudbox]',

}

file_line { 'add-cloudbox-3':
	path	=> '/etc/puppet/puppet.conf',
	line	=> '    modulepath = /etc/puppet/environments/cloudbox/modules',

}

exec { 'restart-puppet':
	command	=> "service puppet restart",
	path	=> "/usr/bin/",
	
}

exec { 'second_foreman-restart':
	command	=> "touch ~foreman/tmp/restart.txt",
	path	=> "/usr/bin/",
	
}













