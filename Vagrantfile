Vagrant.configure("2") do |config|
  # Use the official, highly optimized Ubuntu 20.04 LTS box
  config.vm.box = "ubuntu/focal64"

  # 1. Main K3s Server Node
  config.vm.define "k3s-server" do |server|
    server.vm.hostname = "k3s-server"
    # Static IP on the VirtualBox Host-Only Network so Ansible can find it
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "k3s-server"
    end
  end

  # 2. Worker Nodes (Creates 2 VMs)
  (1..2).each do |i|
    config.vm.define "k3s-worker-#{i}" do |worker|
      worker.vm.hostname = "k3s-worker-#{i}"
      worker.vm.network "private_network", ip: "192.168.56.1#{i}"
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = "1536"
        vb.cpus = 1
        vb.name = "k3s-worker-#{i}"
      end
    end
  end
end