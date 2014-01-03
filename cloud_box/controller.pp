class cloud_box::controller{
 
	include coud_box:params
 
	$admin_password = 'admin_pass'
	$keystone_admin_token = 'keystone_pass'
	 
	class { 'openstack::controller':
	 
		public_address		=> $cloud_box::params::controller_node_public,
		public_interface	=> $cloud_box::params::public_interface,
		private_interface	=> $cloud_box::params::private_interface,
		internal_address	=> $cloud_box::params::controller_node_internal,
		floating_range		=> '192.168.56.128/25',
		fixed_range		=> $cloud_box::params::fixed_range,
		multi_host		=> true,
		network_manager		=> $cloud_box::params::network_manager,
		verbose			=> true,
		auto_assign_floating_ip	=> false,
		mysql_root_password	=> 'mysql_root_password',
		admin_email		=> 'admin@iownz.you',
		admin_password		=> $admin_password,
		keystone_db_password	=> 'keystone_db_password',
		keystone_admin_token	=> $keystone_admin_token,
		glance_db_password	=> 'glance_pass',
		glance_user_password	=> 'glance_pass',
		nova_user_password	=> 'nova_pass',
		nova_user_password	=> $cloud_box::params::nova_user_password,
		rabbit_password		=> $cloud_box::params::rabbit_password,
		rabbit_user		=> $cloud_box::params::rabbit_user,
		export_resources	=> false,
	 
	}

	# Optional: include if you want authorisation information
	# stored in a local file, located in /root/
	#class { 'openstack::auth_file':
	# 
	#	admin_password => $admin_password,
	#	keystone_admin_token => $keystone_admin_token,
	#	controller_node => $icclab::params::controller_node_internal,
	# 
	#}
}
