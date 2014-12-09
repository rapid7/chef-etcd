#
# Cookbook Name:: rapid7-cookbook
# Provider:: source
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
use_inline_resources

action :install do
  package 'git'

  execute "etcd-#{ new_resource.name }-compile" do
    cwd new_resource.cannonical_path
    command './build'
    action :nothing
  end

  ## Checkout from git
  git "etcd-#{ new_resource.name }-clone" do
    repository new_resource.url
    reference new_resource.version
    destination new_resource.cannonical_path

    action :sync
    notifies :run, :execute => "etcd-#{ new_resource.name }-compile"
  end

  ## Link executables to someplace in PATH
  if new_resource.bin_path.is_a?(String)
    link ::File.join(new_resource.bin_path, 'etcd') do
      to new_resource.srv_binary
    end

    link ::File.join(new_resource.bin_path, 'etcdctl') do
      to new_resource.ctl_binary
    end
  end
end
