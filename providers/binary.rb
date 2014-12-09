#
# Cookbook Name:: rapid7-cookbook
# Provider:: binary
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
use_inline_resources

action :install do
  remote_file "etcd-#{ new_resource.name }-github-artifact" do
    path new_resource.package_cache
    source new_resource.github_url
    action :create_if_missing
    only_if { new_resource.from.to_sym == :github }
  end

  libarchive_file "etcd-#{ new_resource.name }-temp-package" do
    path new_resource.package_cache
    extract_to new_resource.path
    extract_options [:no_overwrite]
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
