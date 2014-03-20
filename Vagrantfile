VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  # os image
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.synced_folder ".", "/vagrant"
  if Vagrant.has_plugin?("vagrant-proxyconf")
  	config.proxy.http     = "http://10.0.3.1:3128/"
	config.proxy.https    = "http://10.0.3.1:3128/"
  	config.proxy.no_proxy = "localhost,127.0.0.1"
  end
  
  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on the "Usage" link above
    config.cache.scope = :box

    # If you are using VirtualBox, you might want to use that to enable NFS for
    # shared folders. This is also very useful for vagrant-libvirt if you want
    # bi-directional sync
 #   config.cache.synced_folder_opts = {
 #     type: :nfs,
      # The nolock option can be useful for an NFSv3 client that wants to avoid the
      # NLM sideband protocol. Without this option, apt-get might hang if it tries
      # to lock files needed for /var/cache/* operations. All of this can be avoided
      # by using NFSv4 everywhere. Please note that the tcp option is not the default.
#      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
#    }
  end
  
  # server
  config.vm.define "server" do |server|

	# hostname
	server.vm.hostname = "server.local.cloud"

	# public network
	server.vm.network "public_network", :bridge => 'lxcbr0'

	# private network
	server.vm.network "private_network", ip: "172.16.0.2"
	server.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--nic3", "intnet"]
	end

	# Set the Timezone
	config.vm.provision :shell, :inline => "echo \"Europe/Berlin\" | sudo tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata"

#	# upgrade puppet
#	server.vm.provision :shell, :path => "upgrade-puppet.sh"

	# post installation
	server.vm.provision :shell, :path => "files/System/post-install.sh"
	

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
