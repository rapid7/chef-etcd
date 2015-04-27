#
# Cookbook Name:: rapid7-cookbook
# Library:: etcd_service
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#

## For the lulz, or tags. Whatever...
include Opscode::Aws::Ec2

use_inline_resources

## Search for peers via the AWS/EC2 API
def aws_find_peers
  new_resource.peers = {} # Empty the peer set

  tags = new_resource.aws_tags.map do |key, value|
    {
      :name => "tag:#{ key }",
      :values => value.is_a?(Array) ? value : [value]
    }
  end

  ec2.describe_instances(:filters => tags).data.reservations
    .map(&:instances).flatten
    .reject do |instance|
      instance.instance_id == new_resource.node_name ||
        instance.private_dns_name.nil? ||
        instance.private_dns_name.empty?
    end.each do |instance|
      Chef::Log.info("etcd_service[#{ new_resource.name }] Found peer #{ instance.instance_id }: "\
        "#{ new_resource.protocol }://#{ instance.private_dns_name }:#{ new_resource.peer_port }")
      new_resource.peer(instance.instance_id,
                        new_resource.protocol,
                        instance[new_resource.aws_hostname_key],
                        new_resource.client_port,
                        new_resource.peer_port)
    end
end

action :configure do
  ## Set AWS tags and wait for peers
  if new_resource.discovery == :aws
    Chef::Application.fatal!('recipe[aws::default] is required for etcd_service '\
      'AWS cluster discovery!') unless node.run_list.include?('recipe[aws::default]')

    Chef::Log.info("etcd_service[#{ new_resource.name }] Using AWS discovery")

    ## Set node_name to EC2 instance ID
    Chef::Log.info("etcd_service[#{ new_resource.name }] Setting etcd node_name "\
      "to #{ node['ec2']['instance_id'] }")
    new_resource.node_name(node['ec2']['instance_id'])
    new_resource.client_host(node['ec2']['local_hostname'])
    new_resource.peer_host(node['ec2']['local_hostname'])

    ## Set our own tags
    tag_resource = aws_resource_tag(node['ec2']['instance_id'])
    tag_resource.tags new_resource.aws_tags
    tag_resource.run_action(:update)

    ## Look for other nodes with the same tags
    aws_find_peers

    ## Wait for a quorum to become available
    while new_resource.peers.size < (new_resource.aws_quorum - 1)
      Chef::Log.info("etcd_service[#{ new_resource.name }] Found "\
        "#{ new_resource.peers.size }/#{ new_resource.aws_quorum - 1 } AWS peers")

      sleep 5
      aws_find_peers
    end

    Chef::Log.info("etcd_service[#{ new_resource.name }] Found "\
      "#{ new_resource.peers.size } AWS peers. Success!")
  end

  ## Build etcd arguments
  etcd_arguments = [
    "-name #{ new_resource.node_name }",
    "-data-dir #{ new_resource.data_dir }",
    "-snapshot-count #{ new_resource.snapshot_count }",
    "-heartbeat-interval #{ new_resource.heartbeat_interval }",
    "-election-timeout #{ new_resource.election_timeout }",
    "-listen-client-urls '#{ new_resource.listen_clients.join(',') }'",
    "-listen-peer-urls '#{ new_resource.listen_peers.join(',') }'",
    "-max-snapshots #{ new_resource.max_snapshots }",
    "-max-wals #{ new_resource.max_wals }",
    "-initial-advertise-peer-urls '#{ new_resource.advertise_peers.join(',') }'",
    "-initial-cluster-token '#{ new_resource.token }'",
    "-advertise-client-urls '#{ new_resource.advertise_clients.join(',') }'",
    "-proxy '#{ new_resource.proxy }'"
  ]

  ## Discovery-specific arguments
  case new_resource.discovery
  when :static, :aws
    Chef::Log.info("etcd_service[#{ new_resource.name }] Using static discovery") unless new_resource.discovery == :aws
    etcd_arguments << "-initial-cluster '#{ new_resource.cluster_nodes.join(',') }'"
    etcd_arguments << "-initial-cluster-state #{ new_resource.state }"
  when :etcd
    Chef::Application.fatal!('Attribte discovery_service is required for :etcd '\
    'cliuster discovery') if new_resource.discovery_service.nil?

    Chef::Log.info("etcd_service[#{ new_resource.name }] Using etcd discovery")
    etcd_arguments << "-discovery '#{ new_resource.discovery_service }'"
    etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
    etcd_arguments << "-discovery-proxy #{ new_resource.discovery_proxy }"
  when :dns
    Chef::Application.fatal!('Attribte discovery_domain is required for :dns '\
    'cliuster discovery') if new_resource.discovery_domain.nil?

    Chef::Log.info("etcd_service[#{ new_resource.name }] Using DNS discovery")
    etcd_arguments << "-discovery-srv '#{ new_resource.discovery_domain }'"
    etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
    etcd_arguments << "-initial-cluster-state #{ new_resource.state }"
  else fail "Discovery method #{ new_resource.discovery } is not supported! "\
    'Please select one of :static, :etcd, :dns, or :aws'
  end

  etcd_arguments << "-cors '#{ cors.is_a?(Array) ? cors.join(',') : cors }'" unless new_resource.cors.empty?

  if new_resource.protocol.to_sym == :https
    etcd_arguments << "-cert-file #{ new_resource.cert_file }"
    etcd_arguments << "-key-file #{ new_resource.key_file }"
    etcd_arguments << "-client-cert-auth #{ new_resource.client_cert_auth }"
    etcd_arguments << "-trusted-ca-file #{ new_resource.trusted_ca_file }"
    etcd_arguments << "-peer-cert-file #{ new_resource.peer_cert_file }"
    etcd_arguments << "-peer-key-file #{ new_resource.peer_key_file }"
    etcd_arguments << "-peer-client-cert-auth #{ new_resource.peer_client_cert_auth }"
    etcd_arguments << "-peer-trusted-ca-file #{ new_resource.peer_trusted_ca_file }"
  end

  ## Create service operator
  group new_resource.group do
    system true
  end

  user new_resource.user do
    home '/usr/local/bin'
    shell '/usr/sbin/nologin'
    group new_resource.group
    system true
  end

  ## Upstart service config
  template "/etc/init/etcd-#{ new_resource.name }.conf" do
    cookbook 'etcd'
    source 'etcd.upstart.erb'
    backup false
    variables :resource => new_resource,
              :instance => new_resource.instance_resource,
              :arguments => etcd_arguments
  end

  ## Create the state-store directory
  directory new_resource.data_dir do
    owner new_resource.user
    group new_resource.group
    recursive true
  end

  ## Run it.
  service "etcd-#{ new_resource.name }" do
    supports :restart => true, :status => true
    action new_resource.service_action

    provider Chef::Provider::Service::Upstart
  end
end
