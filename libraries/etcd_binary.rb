require_relative './etcd'

class Chef
  class Resource
    ##
    # An installation of etcd from a compiled release
    ##
    class EtcdBinary < Etcd
      def initialize(name, run_context = nil)
        super

        @provider = Chef::Provider::EtcdBinary
        @resource_name = :etcd_binary
      end

      def from(arg = nil)
        set_or_return(:from, arg, :kind_of => Symbol,
                                  :equal_to => [:github],
                                  :default => :github)
      end

      def repository(arg = nil)
        set_or_return(:repository, arg, :kind_of => String,
                                        :default => node['etcd']['bin_repository'])
      end

      def package_cache
        ::File.join(Chef::Config[:file_cache_path], "#{ package_name }-#{ name }.tgz")
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
