
class Chef
  class Resource
    ##
    # Base resource for a installation of etcd
    ##
    class Etcd < Resource::LWRPBase
      identity_attr :name

      actions :install
      default_action :install

      attribute :version, :kind_of => String,
                          :default => node['etcd']['version']
      attribute :platform, :kind_of => String,
                           :default => node['etcd']['platform']
      attribute :path, :kind_of => String, :default => '/opt'

      attribute :srv_bin, :kind_of => String, :default => 'etcd'
      attribute :ctl_bin, :kind_of => String, :default => 'etcdctl'
      attribute :bin_path, :kind_of => [String, NilCalss, FalseClass],
                           :default => '/usr/local/bin'

      def package_name
        "etcd-#{ version }-#{ platform }"
      end

      def cannonical_name
        "#{ package_name }-#{ name }"
      end

      def cannonical_path
        ::File.join(path, cannonical_name)
      end

      def srv_binary
        ::File.join(cannonical_path, srv_bin)
      end

      def ctl_binary
        ::File.join(cannonical_path, ctl_bin)
      end
    end
  end
end
