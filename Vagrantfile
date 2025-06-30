Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-22.04"
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "10.0.1.15"
    
    master.vm.provider "virtualbox" do |vb|
      vb.memory = 4048
      vb.cpus = 2
    end

    master.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      echo "10.0.1.15  master-node" >> /etc/hosts
      echo "10.0.1.16  worker-node01" >> /etc/hosts
      echo "10.0.1.17  worker-node02" >> /etc/hosts
    SHELL
  end

  (1..2).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.box = "bento/ubuntu-22.04"
      node.vm.hostname = "worker-node0#{i}"
      node.vm.network "private_network", ip: "10.0.1.1#{i + 5}"  # Adjusted IP range
      
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
      end

      node.vm.provision "shell", inline: <<-SHELL
        apt-get update -y
        echo "10.0.1.15  master-node" >> /etc/hosts
        echo "10.0.1.16  worker-node01" >> /etc/hosts
        echo "10.0.1.17  worker-node02" >> /etc/hosts
      SHELL
    end
  end
end