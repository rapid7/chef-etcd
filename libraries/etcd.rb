
class Chef
  class Resource
    ##
    # Base resource for a installation of etcd
    ##
    class Etcd < Chef::Resource
      identity_attr :name

      def initialize(name, run_context = nil)
        super

        ## Actions
        @action = :install
        @allowed_actions << :install
      end

      def version(arg = nil)
        set_or_return(:version, arg, :kind_of => String,
                                     :default => node['etcd']['version'])
      end

      def platform(arg = nil)
        set_or_return(:platform, arg, :kind_of => String,
                                      :default => node['etcd']['platform'])
      end

      def path(arg = nil)
        set_or_return(:path, arg, :kind_of => String, :default => '/opt')
      end

      def srv_bin(arg = nil)
        set_or_return(:srv_bin, arg, :kind_of => String, :default => 'etcd')
      end

      def ctl_bin(arg = nil)
        set_or_return(:ctl_bin, arg, :kind_of => String, :default => 'etcdctl')
      end

      def bin_path(arg = nil)
        set_or_return(:bin_path, arg, :kind_of => [String, NilClass, FalseClass],
                                      :default => '/usr/local/bin')
      end

      def package_name
        "etcd-#{ version }-#{ platform }"
      end

      def cannonical_path
        ::File.join(path, package_name)
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
