#
# Cookbook Name:: rapid7-cookbook
# Recipe:: node
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
include_recipe "#{ cookbook_name }::default"

etcd_binary 'default'
etcd_service 'default' do
  instance 'etcd_binary[default]'
end
