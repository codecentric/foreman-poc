class cloud_box::all_in_one {
 
	$admin_password		= 'admin_pass'
	$keystone_admin_token	= 'keystone_pass'

	class { 'openstack::all':
		public_address		=> $ipaddress_eth0,
		public_interface	=> 'eth0',
		private_interface	=> 'eth1',
		admin_email		=> 'admin@iownz.you',
		admin_password		=> $admin_password,
		keystone_db_password	=> 'keystone_pass',
		keystone_admin_token	=> $keystone_admin_token,
		nova_db_password	=> 'nova_pass',
		nova_user_password	=> 'nova_pass',
		glance_db_password	=> 'glance_pass',
		glance_user_password	=> 'glance_pass',
		rabbit_password		=> 'rabbit_pass',
		rabbit_user		=> 'rabbit_user',
		libvirt_type		=> 'qemu',
		fixed_range		=> '10.0.0.0/24',
		floating_range		=> '192.168.56.128/25',
		verbose			=> true,
		auto_assign_floating_ip	=> false,
	}
	 
	class { 'openstack::auth_file':
		admin_password		=> $admin_password,
		keystone_admin_token	=> $keystone_admin_token,
		controller_node		=> '127.0.0.1',
	}
}
