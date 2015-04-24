#
# Cookbook Name:: rapid7-cookbook
# Provider:: service
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
use_inline_resources

action :configure do
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

  ## Set AWS tags and wait for peers
  if new_resource.discovery == :aws
    Chef::Application.fatal!('recipe[aws::default] is required for etcd_service '\
      'AWS cluster discovery!') unless node.run_list.include?('recipe[aws::default]')

    Chef::Log.info("etcd_service[#{ name }] Using AWS discovery")

    ## Force a couple of defaults. This allows a cluster to converge without
    ## having to pass around additional parameters via tags.
    Chef::Log.info("etcd_service[#{ name }] Setting etcd node name to #{ node['ec2']['instance_id'] }")
    new_resource.node_name = node['ec2']['instance_id']
    new_resource.peer_port = 2380

    ## Set our own tags
    aws_resource_tag node['ec2']['instance_id'] do
      tags new_resource.aws_tags
      action :update
    end

    ## Look for other nodes with the same tags
    new_resource.aws_find_peers

    ## Wait for a quorum to become available
    while peers.size < new_resource.aws_quorum
      Chef::Log.info("etcd_service[#{ name }] Found #{ peers.size } AWS "\
        "peers: #{ peers.map { |_, peer| peer[:host] }.join(', ') }")
      Chef::Log.info("etcd_service[#{ name }] Waiting for #{ new_resource.aws_quorum } AWS peers")

      sleep 5
      new_resource.aws_find_peers
    end

    Chef::Log.info("etcd_service[#{ name }] Found #{ peers.size } AWS "\
      "peers: #{ peers.map { |_, peer| peer[:host] }.join(', ') }")
  end

  case new_resource.discovery
  when :static, :aws
    Chef::Log.info("etcd_service[#{ name }] Using static discovery") unless new_resource.discovery == :aws
    etcd_arguments << "-initial-cluster '#{ new_resource.cluster_nodes.join(',') }'"
    etcd_arguments << "-initial-cluster-state #{ new_resource.state }"
  when :etcd
    Chef::Application.fatal!('Attribte discovery_service is required for :etcd '\
    'cliuster discovery') if new_resource.discovery_service.nil?

    Chef::Log.info("etcd_service[#{ name }] Using etcd discovery")
    etcd_arguments << "-discovery '#{ new_resource.discovery_service }'"
    etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
    etcd_arguments << "-discovery-proxy #{ new_resource.discovery_proxy }"
  when :dns
    Chef::Application.fatal!('Attribte discovery_domain is required for :dns '\
    'cliuster discovery') if new_resource.discovery_domain.nil?

    Chef::Log.info("etcd_service[#{ name }] Using DNS discovery")
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
