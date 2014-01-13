class cloud_box::params{
  
	/* -----------Shared Connection Settings-------------*/
	########### Important to set! ############
	$controller_node_address	= '172.16.0.98'
	$controller_node_public		= controller_node_address
	$controller_node_internal	= controller_node_address
	$sql_connection			= "mysql://nova:${cloud_box::params::nova_db_password}@${controller_node_internal}/nova"
	 
	/* --------------------------------------------------*/
	 
	 
	/* -------------Shared Auth Settings-----------------*/
	$nova_user_password	= 'nova_pass'
	$rabbit_password	= 'rabbit_pass'
	$rabbit_user		= 'rabbit_user'
	/* --------------------------------------------------*/
	 
	 
	/* ----------Shared Networking Settings--------------*/
	$network_manager	= 'nova.network.manager.FlatDHCPManager'
	$fixed_range		= '172.16.0.16 172.16.0.255'
	$public_interface	= 'eth0'
	$private_interface	= 'eth1'
	/* --------------------------------------------------*/
 
}
