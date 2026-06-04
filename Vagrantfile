Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.boot_timeout = 600

  # 1. Main K3s Server Node
  config.vm.define "k3s-server" do |server|
    server.vm.hostname = "k3s-server"
    server.vm.network "private_network", ip: "192.168.56.10"
    server.ssh.host = "192.168.56.1"
    
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "k3s-server"
      vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
      vb.customize ["modifyvm", :id, "--natpf1", "wsl-ssh,tcp,,2222,,22"]
    end
  end

  # 2. Worker Nodes (Creates 2 VMs)
  (1..2).each do |worker_index|
    config.vm.define "k3s-worker-#{worker_index}" do |worker|
      worker.vm.hostname = "k3s-worker-#{worker_index}"
      worker.vm.network "private_network", ip: "192.168.56.1#{worker_index}"
      worker.ssh.host = "192.168.56.1"
      
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = "1536"
        vb.cpus = 1
        vb.name = "k3s-worker-#{worker_index}"
        vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
        vb.customize ["modifyvm", :id, "--natpf1", "wsl-worker-ssh-#{worker_index},tcp,,220#{worker_index},,22"]
      end
    end
  end
end