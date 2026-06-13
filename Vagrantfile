# --- HOST COMPATIBILITY PATCH ---
# Fixes a known Kali Linux bug where VBoxManage outputs a libxml compilation warning.
# This warning misleads Vagrant into thinking the interface name contains the warning text.
if Dir.exist?('/etc/apt') # Target Linux hosts specifically
  require 'vagrant/util/subprocess'
  module Vagrant
    module Util
      class Subprocess
        class << self
          alias_method :original_execute, :execute
          def execute(*command, &block)
            result = original_execute(*command, &block)
            if result && result.stdout
              # Clean the standard output stream of the libxml noise before returning it to Vagrant
              result.stdout.gsub!(/^Warning: program compiled against libxml.*\n/, '')
            end
            result
          end
        end
      end
    end
  end
end
# ---------------------------------




Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  # 1. Main K3s Server Node (Master)
  config.vm.define "k3s-server" do |server|
    server.vm.hostname = "k3s-server"
    server.vm.network "private_network", ip: "192.168.56.10"
    
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "k3s-server"
    end

    #  Assigns the missing IP to Kali right after boot
    # This ensures the script fires on boot, reload, or manual provisioning
    server.trigger.after :up, :reload, :provision do |trigger|
      trigger.info = "Executing local host network synchronization script..."
      trigger.run = {path: "./fix-host-network.sh"}
    end
  end

  # 2. Worker Nodes (Creates 2 VMs automatically)
  (1..2).each do |i|
    config.vm.define "k3s-worker-#{i}" do |worker|
      worker.vm.hostname = "k3s-worker-#{i}"
      worker.vm.network "private_network", ip: "192.168.56.1#{i}", id: "vboxnet0"
      
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = "1536"
        vb.cpus = 1
        vb.name = "k3s-worker-#{i}"
      end
    end
  end
end