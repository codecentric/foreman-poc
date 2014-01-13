class cloud_box::compute{
 
	include cloud_box::params
 
	class { 'openstack::compute':
	 
		public_interface	=> $cloud_box::params::public_interface,
		private_interface	=> $cloud_box::params::private_interface,
		internal_address	=> $ipaddress_eth0,
		libvirt_type		=> 'qemu',
		fixed_range		=> $cloud_box::params::fixed_range,
		network_manager		=> $cloud_box::params::network_manager,
		multi_host		=> true,
		sql_connection		=> $cloud_box::params::sql_connection,
		nova_user_password	=> $cloud_box::params::nova_user_password,
		rabbit_host		=> $cloud_box::params::controller_node_internal,
		rabbit_password		=> $cloud_box::params::rabbit_password,
		rabbit_user		=> $cloud_box::params::rabbit_user,
		glance_api_servers	=> "${cloud_box::params::controller_node_internal}:9292",
		vncproxy_host		=> $cloud_box::params::controller_node_public,
		vnc_enabled		=> true,
		verbose			=> true,
		manage_volumes		=> true,
		nova_volume		=> 'nova-volumes'
	 
	}
}
