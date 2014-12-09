require_relative './etcd'

class Chef
  class Resource
    ##
    # An installation of etcd from source
    ##
    class EtcdSource < Etcd
      provides :etcd_source
      self.resource_name = :etcd_source

      attribute :url, :kind_of => String, :default => node['etcd']['source_repository']

      def srv_binary
        ::File.join(cannonical_path, 'bin', srv_bin)
      end

      def ctl_binary
        ::File.join(cannonical_path, 'bin', ctl_bin)
      end
    end
  end
end
