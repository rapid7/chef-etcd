#
# Cookbook Name:: etcd
# Library:: etcd_service
#
# The MIT License (MIT)
# =====================
# Copyright (C) 2015 Rapid7 LLC.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

## For the lulz, or tags. Whatever...
begin
  include Opscode::Aws::Ec2
  include ETCD::AWSHelpers
rescue NameError
  Chef::Log.warn('The `aws` cookbook has not been loaded. AWS cluster discovery '\
    'is not available!')
end

include ETCD::Helpers

use_inline_resources

action :configure do
  ## Set AWS tags and wait for peers
  if new_resource.discovery == :aws
    Chef::Log.info("etcd_service[#{ new_resource.name }] Using AWS discovery")
    Chef::Application.fatal!('recipe[aws::default] is required for etcd_service '\
      'AWS cluster discovery!') unless node.run_list.include?('recipe[aws::default]')

    aws_discovery_bootstrap
    autoconfigure_node
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
    cookbook 'etcd-v2'
    source 'etcd.upstart.erb'
    backup false
    variables :resource => new_resource,
              :instance => new_resource.instance_resource,
              :arguments => build_arguments
    only_if { node['platform_family'] == 'debian' }
  end

  # Init.d service config
  template "/etc/init.d/etcd-#{new_resource.name}" do
    cookbook 'etcd-v2'
    source 'etcd.initd.erb'
    backup false
    mode 0755
    variables :arguments => build_arguments
    only_if { node['platform_family'] == 'rhel' }
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

    provider Chef::Provider::Service::Upstart if node['platform_family'] == 'debian'
    provider Chef::Provider::Service::Init::Redhat if node['platform_family'] == 'rhel'
  end
end
