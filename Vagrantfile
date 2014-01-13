VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  # os image
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # server
  config.vm.define "server" do |server|

	# hostname
	server.vm.hostname = "server.local.cloud"

	# public network
	server.vm.network "public_network", :bridge => 'eth0'

	# private network
	server.vm.network "private_network", ip: "172.16.0.2"
	server.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--nic3", "intnet"]
	end

	# Set the Timezone
	config.vm.provision :shell, :inline => "echo \"Europe/Berlin\" | sudo tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata"

	# upgrade puppet
	server.vm.provision :shell, :path => "upgrade-puppet.sh"

	# provisioning with puppet
	server.vm.provision "puppet" do |puppet|
		puppet.manifests_path = "manifests"
		puppet.manifest_file = "server.pp"
		puppet.module_path = "modules"
	end
  end

  # client
  config.vm.define "client" do |client|

	# hostname
	client.vm.hostname = "client"

	# private network
	client.vm.network "private_network", type: :dhcp
	client.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--nic2", "intnet"]
	end

	# Set the Timezone
	config.vm.provision :shell, :inline => "echo \"Europe/Berlin\" | sudo tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata"

	# upgrade puppet
	client.vm.provision :shell, :path => "upgrade-puppet.sh"

	# provisioning with puppet
        client.vm.provision "puppet" do |puppet|
                puppet.manifests_path = "manifests"
                puppet.manifest_file = "client.pp"
		puppet.module_path = "modules"
        end
  end

end
