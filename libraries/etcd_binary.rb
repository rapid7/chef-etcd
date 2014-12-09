require_relative './etcd'

class Chef
  class Resource
    ##
    # An installation of etcd from a compiled release
    ##
    class EtcdBinary < Etcd
      provides :etcd_binary
      self.resource_name = :etcd_binary


      attribute :from, :kind_of => Symbol,
                       :equal_to => [:github],
                       :default => :github
      attribute :repository, :kind_of => String, :default => node['etcd']['bin_repository']

      def package_cache
        ::File.join(Chef::Config[:file_cache_path], "#{ cannonical_name }.tgz")
      end

      def github_artifact
        "#{ package_name }.tar.gz"
      end

      def github_url
        "https://github.com/#{ repository }/releases/download/#{ version }/#{ github_artifact }"
      end
    end
  end
end
