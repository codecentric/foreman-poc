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
	content	=> 'deb http://deb.theforeman.org/ trusty 1.6'
}

file {'smartproxylist':
	path	=> '/etc/apt/sources.list.d/smartproxy.list',
	ensure	=> present,
	mode	=> 0644,
	content	=> 'deb http://deb.theforeman.org/ trusty stable'
}

file {'foreman-pluginlist':
        path    => '/etc/apt/sources.list.d/foreman-plugins.list',
        ensure  => present,
        mode    => 0644,
        content => 'deb http://deb.theforeman.org/ plugins 1.6'
}

aptkey { 'foreman.asc':
	ensure	=> present
}

# update and source installation
exec { "apt-update":
	command	=> "/usr/bin/apt-get update",
	require	=> [
		Aptkey['foreman.asc'],
		File['smartproxylist'],
		File['foremanlist'],
		File['foreman-pluginlist'],
	]
}

package { "make":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
}

package { "openssh-server":
	ensure	=> "installed",
	require	=> Exec['apt-update'],
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
package { "git":
	ensure  => "installed",
	require => Exec['apt-update'],
}
package { "gem":
	ensure => "installed",
	install_options => [ '--force-yes'],
	require => Exec['apt-update'],
}

# placing the keyfile
file { "/etc/bind/rndc.key":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/BIND/rndc.key",
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
	source	=> "/home/server/git/foreman-poc/files/DHCP/apparmor_usr.sbin.dhcpd",
	require => Package["isc-dhcp-server"],
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
	require	=> File["/var/lib/tftpboot"],
}

# netboot image directory
file { '/var/lib/tftpboot/boot':
	ensure	=> directory,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	require	=> File["/var/lib/tftpboot"],
}

# copy image for Ubuntu 12.10
file { '/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-initrd.gz':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/home/server/git/foreman-poc/files/TFTP/ubuntu12.10/initrd.gz",
	require	=> File["/var/lib/tftpboot/boot"],
}

file { '/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-linux':
	ensure	=> present,
	owner	=> nobody,
	group	=> nogroup,
	mode	=> 777,
	source	=> "/home/server/git/foreman-poc/files/TFTP/ubuntu12.10/linux",
	require	=> File["/var/lib/tftpboot/boot"],
}

# download discovery images
exec { "wget initrd.img":
       command => "wget http://downloads.theforeman.org/discovery/releases/0.5/foreman-discovery-image-latest.el6.iso-img",
       cwd     => "/var/lib/tftpboot/boot/",
       creates => "/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-img",
       path    => "/usr/bin",
       timeout => 1000,
       require => File["/var/lib/tftpboot/boot"],
}


exec { "wget vmlinuz":
        command => "wget http://downloads.theforeman.org/discovery/releases/0.5/foreman-discovery-image-latest.el6.iso-vmlinuz",
        cwd     => "/var/lib/tftpboot/boot/",
        creates => "/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-vmlinuz",
        path    => "/usr/bin",
        timeout => 1000,
        require => File["/var/lib/tftpboot/boot"],
}


# set permissions for discovery images
file { '/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-img':
      ensure  => present,
      owner   => foreman-proxy,
      group   => nogroup,
      mode    => 644,
     require => Exec["wget initrd.img"],
}


file { '/var/lib/tftpboot/boot/foreman-discovery-image-latest.el6.iso-vmlinuz':
      ensure  => present,
      owner   => foreman-proxy,
      group   => nogroup,
      mode    => 644,
      require => Exec["wget vmlinuz"],
}


# options for foreman-installer
file { "/etc/foreman/foreman-installer-answers.yaml":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/Foreman/answers.yaml",
	owner	=> root,
	group	=> root,
	mode	=> 600,
	require	=> Package["foreman-installer"],
}

# modifying foreman-installer to support DDNS
file { "/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/DHCP/proxydhcp.pp",
	owner	=> root,
	group	=> root,
	mode	=> 644,
	require	=> Package["foreman-installer"],
}



# installation foreman
exec { 'foreman-installer':
	command	=> "/usr/sbin/foreman-installer --foreman-admin-password changeme",
	environment => ["HOME=/home/server"],
	timeout => 0,
	require => [
		Package["bind9"],
		File['/usr/share/foreman-installer/modules/foreman_proxy/manifests/proxydhcp.pp'],
		File['/etc/foreman/foreman-installer-answers.yaml'],
		File["/etc/bind/rndc.key"],
	],
}


# adding user 'foreman-proxy' to group 'bind', as this users needs to read the keyfile
user { "foreman-proxy":
	ensure	=> present,
	groups	=> ['bind'],
	require => Exec["foreman-installer"],
}

# foreman settings
file { "/etc/foreman/settings.yaml":
	ensure	=> present,
	source	=> "/home/server/git/foreman-poc/files/Foreman/settings.yaml",
	owner	=> root,
	group	=> foreman,
	mode	=> 640,
	require	=> Exec["foreman-installer"],
}

exec { "foreman-restart":
	command		=> "touch ~foreman/tmp/restart.txt",
	subscribe	=> File["/etc/foreman/settings.yaml"],
	refreshonly	=> true,
	path		=> "/usr/bin/",
}

exec { "foreman-cache":
	command		=> "/usr/sbin/foreman-rake apipie:cache",
	require		=> Exec['foreman-restart'],
}

# ruby-dev
# install ruby-dev package
package { 'ruby-dev':
	ensure		=> installed,
	require	=> Exec['apt-update'],
}


# HAMMER
# install hammer cli
package { 'hammer_cli':
	ensure		=> installed,
	provider	=> "gem",
	require => [
			Package['gem'],
			Package['ruby-dev'],
		   ],
}

# install foreman plugin for hammer
package { 'hammer_cli_foreman':
	ensure	=> installed,
	provider => "gem",
	require => [
			Package["hammer_cli"],
			Exec["foreman-installer"],
		   ],
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
	require	=> [File['/etc/hammer'], Exec['foreman-installer'],]
}

# hammer logging
file { '/var/log/foreman/hammer.log':
	ensure	=> present,
	mode	=> 777,
	require	=> Exec['foreman-installer'],
}

exec { "hammer execution":
	command	=> "/home/server/git/foreman-poc/hammer/hammer.sh",
	path	=> "/usr/local/bin/",
	require	=> [
			File["/var/log/foreman/hammer.log"],
			File["/etc/hammer/cli_config.yml"],
			Package["hammer_cli_foreman"],
		],
#	onlyif  => "hammer architecture list | /bin/grep -q 'x86_64'",
	user	=> "server",
	environment	=> ["HOME=/home/server"],
}



# generate pxe 

# host



# firewall

# uncomment IP forwarding
exec { 'net.ipv4.ip_forward':
	command	=> "/bin/sed -i -e'/#net.ipv4.ip_forward=1/s/^#\\+//' '/etc/sysctl.conf'",
	onlyif	=> "/bin/grep '#net.ipv4.ip_forward=1' '/etc/sysctl.conf' | /bin/grep '^#' | /usr/bin/wc -l",
}

# no restart necessary
exec { 'sysctl':
	command	=> "sysctl -w net.ipv4.ip_forward=1",
	path	=> "/sbin/",
	require	=> Exec["net.ipv4.ip_forward"],
}

# create firewall rules
exec { 'iptables forward':
	command	=> "iptables -P FORWARD ACCEPT",
	path	=> "/sbin",
	require	=> Exec["sysctl"],
}
exec { 'iptables masquerade':
	command	=> "iptables --table nat -A POSTROUTING -o eth1 -j MASQUERADE",
	path	=> "/sbin",
	require	=> Exec["iptables forward"],
}

# preseed iptables-persistent
package{ 'debconf-utils':
	ensure	=> installed,
}

exec { 'preseed':
	command	=> "debconf-set-selections /home/server/git/foreman-poc/files/System/iptables-persistent.seed",
	path	=> "/usr/bin/",
	require	=> [
			Package['debconf-utils'],
		],
}

# install iptables-persistent
package { 'iptables-persistent':
	ensure	=> installed,
	require	=> Exec["iptables masquerade"],
}

# start iptables-persistent
service { "iptables-persistent":
	ensure	=> running,
	require	=> Package["iptables-persistent"],
}

# Install local ubuntu repository: apt-cacher
service { "apache2":
	ensure  => "running",
	enable  => "true",
	require	=> Exec['foreman-installer'],
}

package { 'apt-cacher':
	ensure	=> installed,
	require	=> Service['apache2'],
}

service { "apt-cacher":
	ensure  => "running",
	enable  => "true",
	require	=> Package['apt-cacher'],
}

file { '/etc/apt-cacher/apt-cacher.conf':
	ensure	=> present,
	owner	=> root,
	group	=> root,
	mode	=> 644,
	source	=> "/home/server/git/foreman-poc/files/System/apt-cacher.conf",
	notify  => Service["apt-cacher"],
	require	=> Package["apt-cacher"],
}

exec {'apt-cacher-import':
	command => "apt-cacher-import.pl -r /var/cache/apt/archives",
	path	=> "/usr/share/apt-cacher/",
	require => File["/etc/apt-cacher/apt-cacher.conf"],
}

file_line { 'sudo_rule_v1':
	path	=> '/etc/sudoers',
	line	=> 'Defaults:foreman-proxy !requiretty',
	require	=> Exec['foreman-installer'],
}

file_line { 'sudo_rule_v2':
	path	=> '/etc/sudoers',
	line	=> 'foreman-proxy ALL = NOPASSWD: /usr/bin/puppet kick *',
	require	=> File_Line['sudo_rule_v1'],
}
 
file_line { 'sudo_rule_v3':
	path	=> '/etc/sudoers',
	line	=> 'foreman-proxy ALL = NOPASSWD: /usr/bin/puppet cert *',
	require	=> File_Line['sudo_rule_v2'],
}

exec { "gem-foreman-discovery":

       command => "gem install --no-rdoc --no-ri foreman_discovery",
       cwd     => "/usr/share/foreman",
       path    => "/usr/bin",
       require => [
			Exec['foreman-installer'],
		]
}

exec { "bundle-update":

       command => "bundle update",
       cwd     => "/usr/share/foreman",
       path    => "/usr/bin",
        require => [
			Exec['gem-foreman-discovery'],
		]
}

exec { "foreman-discovery-postinstall":

       command => "ruby-foreman-discovery.postinst",
       cwd     => "/var/lib/dpkg/info",
       path    => "/usr/bin",
        require => [
			Exec['bundle-update'],
		]
}

exec { "foreman-discovery-install-f":

       command => "apt-get -f install",
       path    => "/usr/bin",
        require => [
			Exec['foreman-discovery-postinstall'],
		]
}



package { 'ruby-foreman-discovery':
        ensure  => installed,
        require => [
			Exec['foreman-discovery-install-f'],
		]
}


#exec { "reboot machine":
#	command => "/sbin/reboot",
#	require	=> [
#		Package['openssh-server'],
#		Package['git'],
#		User['dhcpd'],
#		Service['apparmor'],
#		File['/etc/apparmor.d/usr.sbin.dhcpd'],
#		File_line['dhclient'],
#		File['/var/lib/tftpboot/boot/Ubuntu-12.10-x86_64-linux'],
#		User['foreman-proxy'],
#		File['/etc/foreman/settings.yaml'],
#		Exec['foreman-restart'],
#		Exec['hammer execution'],
#		Exec['iptables masquerade'],
#		Exec['preseed'],
#		Service['iptables-persistent'],
#		Exec['apt-cacher-import'],
#		File_Line['sudo_rule_v3'],
#		Package['ruby-foreman-discovery'],
#	],
#}
