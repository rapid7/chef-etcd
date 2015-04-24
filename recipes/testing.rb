#
# Cookbook Name:: rapid7-cookbook
# Recipe:: default
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
include_recipe "#{ cookbook_name }::default"

etcd_binary 'default'

etcd_service 'node0' do
  instance 'etcd_binary[default]'
  client_port 2379
  peer_host 'localhost'
  peer_port 2380

  peer 'node1', :http, 'localhost', 2381, 2382
  peer 'node2', :http, 'localhost', 2383, 2384

  data_dir '/var/data/etcd-node0'
end

etcd_service 'node1' do
  instance 'etcd_binary[default]'
  client_port 2381
  peer_host 'localhost'
  peer_port 2382

  peer 'node0', :http, 'localhost', 2379, 2380
  peer 'node2', :http, 'localhost', 2383, 2384

  data_dir '/var/data/etcd-node1'
end

etcd_service 'node2' do
  instance 'etcd_binary[default]'
  client_port 2383
  peer_host 'localhost'
  peer_port 2384

  peer 'node0', :http, 'localhost', 2379, 2380
  peer 'node1', :http, 'localhost', 2381, 2382

  data_dir '/var/data/etcd-node2'
end
