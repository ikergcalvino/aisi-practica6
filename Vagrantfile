# -*- mode: ruby -*-
# vi: set ft=ruby :
require_relative 'provisioning/vbox.rb'
VBoxUtils.check_version('6.1.32')
Vagrant.require_version ">= 2.2.19"

# Hostnames for master and worker nodes
MASTER_HOSTNAME = "xxx-aisi2122-master"
WORKER_HOSTNAME = "xxx-aisi2122-worker"

# Master settings
MASTER_IP = "10.10.1.10"
MASTER_MEM = 1024
MASTER_CORES = 1

# Worker settings
NUM_WORKERS = 2
WORKER_MEM = 2048
WORKER_CORES = 2

require 'ipaddr'
CLUSTER_IP_ADDR = IPAddr.new MASTER_IP
CLUSTER_IP_ADDR = CLUSTER_IP_ADDR.succ

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"
  config.vm.box_version = "11.20211230.1"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Configure hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = true

  # Master node
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = MASTER_HOSTNAME
    master.vm.network :private_network, ip: MASTER_IP, virtualbox__intnet: true
    
    master.vm.provider :virtualbox do |prov|
        prov.name = "AISI-P6-#{master.vm.hostname}"
        prov.cpus = MASTER_CORES
        prov.memory = MASTER_MEM
	prov.gui = false

	# Add disks
        for i in 0..1 do
            filename = "./disks/#{master.vm.hostname}-disk#{i}.vdi"
            unless File.exist?(filename)
                prov.customize ["createmedium", "disk", "--filename", filename, "--format", "vdi", "--size", 5 * 1024]
            end
	    prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", i + 1, "--device", 0, "--type", "hdd", "--medium", filename]
        end
    end

    # Install ansible on the master node
    master.vm.provision "ansible_local" do |ansible|
        ansible.install = "true"
        ansible.install_mode = "pip3"
	ansible.playbook = "provisioning/playbook.yml"
    end
  end
  
  # Worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "worker-#{i}" do |worker|
	worker.vm.hostname = "#{WORKER_HOSTNAME}-#{i}"
	IP_ADDR = CLUSTER_IP_ADDR.to_s
        CLUSTER_IP_ADDR = CLUSTER_IP_ADDR.succ
        worker.vm.network :private_network, ip: IP_ADDR, virtualbox__intnet: true
        
        worker.vm.provider :virtualbox do |prov|
	    prov.name = "AISI-P6-#{worker.vm.hostname}"
            prov.cpus = WORKER_CORES
            prov.memory = WORKER_MEM
	    prov.gui = false

	    # Add disks
            for j in 0..1 do
                filename = "./disks/#{worker.vm.hostname}-disk#{j}.vdi"
                unless File.exist?(filename)
                    prov.customize ["createmedium", "disk", "--filename", filename, "--format", "vdi", "--size", 5 * 1024]
                end
		prov.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", j + 1, "--device", 0, "--type", "hdd", "--medium", filename]
            end
        end
    end
  end
  
  # Global provisioning bash script
  config.vm.provision "shell", path: "./provisioning/bootstrap.sh"
end
