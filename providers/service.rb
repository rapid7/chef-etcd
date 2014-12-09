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
    home new_resource.instance_resource.link
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
    "-listen-peer-urls '#{ new_resource.listen_peers.join(',') }'",
    "-listen-client-urls '#{ new_resource.listen_clients.join(',') }'",
    "-max-snapshots #{ new_resource.max_snapshots }",
    "-max-wals #{ new_resource.max_wals }",
    "-initial-advertise-peer-urls '#{ new_resource.advertise_peers.join(',') }'",
    "-initial-cluster-token '#{ new_resource.cluster_token }'",
    "-advertise-client-urls '#{ new_resource.advertise_clients.join(',') }'",
    "-proxy '#{ new_resource.proxy }'"
  ]

  case new_resource.discovery
  when :static
    etcd_arguments << "-initial-cluster '#{ new_resource.cluster_nodes }'"
    etcd_arguments << "-initial-cluster-state #{ new_resource.cluster_state }"
  when :etcd
    etcd_arguments << "-discovery '#{ new_resource.discovery_service }'"
    etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
    etcd_arguments << "-discovery-proxy #{ new_resource.discovery_proxy }"
  when :dns
  when :aws
  else
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

    notifies :restart, :service => "etcd-#{ new_resource.name }"
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
