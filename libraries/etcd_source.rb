#
# Cookbook Name:: rapid7-cookbook
# Library:: etcd_source
#
# Copyright (C) 2015 Rapid7 LLC.
#
# All rights reserved - Do Not Redistribute
#
require_relative './etcd'

class Chef
  class Resource
    ##
    # An installation of etcd from source
    ##
    class EtcdSource < Etcd
      def initialize(name, run_context = nil)
        super

        @provider = Chef::Provider::EtcdSource
        @resource_name = :etcd_source
      end

      def url(arg = nil)
        set_or_return(:url, arg, :kind_of => String,
                                 :default => node['etcd']['source_repository'])
      end

      def srv_binary
        ::File.join(cannonical_path, 'bin', srv_bin)
      end

      def ctl_binary
        ::File.join(cannonical_path, 'bin', ctl_bin)
      end
    end
  end
end
