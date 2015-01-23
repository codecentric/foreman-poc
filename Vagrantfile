VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  # os image
  config.vm.box = "ubuntu/trusty64"
  config.vm.synced_folder ".", "/vagrant"
 
  # Vagrant Proxy plugin
  if Vagrant.has_plugin?("vagrant-proxyconf")
  	config.proxy.http     = "http://10.0.3.1:3128/"
	config.proxy.https    = "http://10.0.3.1:3128/"
  	config.proxy.no_proxy = "localhost,127.0.0.1"
  end
  
  # Vagrant cachier plugin
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
 
  config.vm.define "server" do |server|

        server.vm.provider :virtualbox do |vb|
        	vb.customize ['modifyvm', :id,'--memory', '2048']
		vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
		vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
	end

	# hostname
	server.vm.hostname = "server.local.cloud"

	# public network
	server.vm.network "public_network"
	#, :bridge => 'eth0'

	# private network
	server.vm.network "private_network", ip: "172.16.0.2"
	server.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--nic3", "intnet"]
	end

	# Set the Timezone
	config.vm.provision :shell, :inline => "echo \"Europe/Berlin\" | sudo tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata"

	# post installation
	server.vm.provision :shell, :path => "files/System/post-install.sh"
	
	# provisioning with puppet
	server.vm.provision "puppet" do |puppet|
		puppet.manifests_path = "manifests"
		puppet.manifest_file = "server.pp"
		puppet.module_path = "modules"
	end
  end
end
