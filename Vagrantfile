# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise"
  config.vm.provision :shell, :path => "build.sh"

  config.vm.provider "virtualbox" do |v|
    # Make us faster
    v.customize [ "modifyvm", :id, "--memory", "1536", "--cpus", "2" ]
    v.customize ['storagectl', :id, '--name', 'SATA Controller', '--hostiocache', 'on']
    v.customize ['storagectl', :id, '--name', 'SATA Controller', '--controller', 'IntelAHCI']
    v.customize ['modifyvm', :id, "--chipset", "ich9"]
  end
end
