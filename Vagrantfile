# # vi: set ft=ruby sw=2 :

require 'fileutils'

$hosts = File.open 'hosts' do |file|
  Hash[file.each_line.map { |line| line.chomp.split(' ').reverse }]
end

def set_host config, name
  config.vm.hostname = "#{name}.local"
  config.vm.network :private_network, ip: $hosts["#{name}.local"], virtualbox__intnet: true
  config.vm.network :private_network, ip: $hosts["#{name}.local"].sub("172.17", "172.18")
end

Vagrant.configure('2') do |config|
  config.vm.box = 'coreos-alpha'
  config.vm.box_version = '>= 308.0.1'
  config.vm.box_url = 'http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json'

  config.vm.provider :virtualbox do |vb|
    vb.check_guest_additions = false
    vb.functional_vboxsf = false
    vb.memory = 512
    vb.cpus = 1
  end

  if Vagrant.has_plugin?('vagrant-vbguest') then
    config.vbguest.auto_update = false
  end

  config.vm.provision :file, source: 'hosts', destination: '/tmp/hosts'
  config.vm.provision :file, source: 'user-data/base', destination: '/tmp/vagrantfile-user-data'
  config.vm.provision :file, source: '/dev/null', destination: '/tmp/vagrantfile-extra-user-data', id: :extra_user_data

  config.vm.provision :shell, inline: <<-SCRIPT, privileged: true
    mv /tmp/hosts /etc
    mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
    mv /tmp/vagrantfile-extra-user-data /var/lib/coreos-vagrant/
  SCRIPT

  config.vm.define :master, primary: true do |vm_config|
    set_host vm_config, :master
    vm_config.vm.network :forwarded_port, guest: 9174, host: 9174 # For p2pool
    vm_config.vm.network :forwarded_port, guest: 5889, host: 5889 # For Vertcoin Blockchain Sync
    vm_config.vm.synced_folder 'share', '/tmp/share', type: 'nfs', mount_options: ['nolock,vers=3,udp']
    vm_config.vm.provision :file, source: 'user-data/master', destination: '/tmp/vagrantfile-extra-user-data', id: :extra_user_data, preserve_order: true
  end

  config.vm.define :registry, autostart: false do |vm_config|
    set_host vm_config, :registry
    vm_config.vm.synced_folder 'dockerfiles', '/tmp/dockerfiles', type: 'nfs', mount_options: ['nolock,vers=3,udp']
    vm_config.vm.synced_folder 'registry', '/tmp/registry', type: 'nfs', mount_options: ['nolock,vers=3,udp']
    vm_config.vm.provision :file, source: 'user-data/registry', destination: '/tmp/vagrantfile-extra-user-data', id: :extra_user_data, preserve_order: true
  end
end
