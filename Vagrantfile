# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.hostname = 'etcd-testing'
  config.vm.box = 'ubuntu-14.04-provisionerless'
  config.vm.box_url = 'https://cloud-images.ubuntu.com/vagrant/trusty/'\
    'current/trusty-server-cloudimg-amd64-vagrant-disk1.box'

  config.vm.provider :aws do |aws, override|
    if Vagrant.has_plugin?('vagrant-secret')
      aws.access_key_id = Secret.access_key_id
      aws.secret_access_key = Secret.secret_access_key
      aws.keypair_name = Secret.keypair_name

      aws.subnet_id = Secret.subnet_id
      aws.security_groups = Secret.security_groups
      aws.iam_instance_profile_arn = Secret.iam_instance_profile_arn
    end

    aws.associate_public_ip = false
    aws.ssh_host_attribute = :private_ip_address

    aws.ami = 'ami-f63b3e9e' # Trusty 27.04.2015
    aws.region = 'us-east-1'
    aws.instance_type = 't2.micro'

    override.vm.box = 'aws'
    override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
    override.ssh.username = 'ubuntu'
    override.ssh.private_key_path = File.join(ENV['HOME'], '.ssh/id_rsa')
  end if Vagrant.has_plugin?('vagrant-aws')

  config.vm.provider :virtualbox do |_, override|
    override.vm.network :forwarded_port, :host => 2379, :guest => 2379
  end

  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true
  config.berkshelf.berksfile_path = './Berksfile'

  config.vm.provision :chef_solo do |chef|
    # chef.log_level = :debug
    chef.json = {
      :vagrant => true
    }

    chef.run_list = [
      'recipe[aws::default]',
      'recipe[aws::ec2_hints]',
      'recipe[etcd::aws]'
    ]
  end

  ## Build a cluster
  3.times do |i|
    config.vm.define "node-#{i}"
  end
end
