#
# Cookbook Name:: etcd
# Resource:: service
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
class Chef
  class Resource
    ##
    # Manage an etcd configuration and resulting service
    ##
    class EtcdService < Resource
      identity_attr :node_name
      attr_accessor :peers

      def initialize(*_)
        super

        @action = :configure
        @allowed_actions << :configure
        @provider = Chef::Provider::EtcdV2Service
        @resource_name = :etcd_service

        @peers = []
      end

      def node_name(arg = nil)
        set_or_return(:node_name, arg, :name_attribute => true)
      end

      def instance(arg = nil)
        set_or_return(:instance, arg, :kind_of => [String, Hash, Resource::Etcd],
                                      :required => true)
      end

      def user(arg = nil)
        set_or_return(:user, arg, :kind_of => String, :default => 'etcd')
      end

      def group(arg = nil)
        set_or_return(:group, arg, :kind_of => String, :default => 'etcd')
      end

      def service_action(arg = nil)
        set_or_return(:service_action, arg, :kind_of => [Symbol, Array],
                                            :default => [:start, :enable])
      end

      ## Node configuration/tuning
      def client_host(arg = nil)
        set_or_return(:client_host, arg, :kind_of => [String, Array],
                                         :default => node['ipaddress'])
      end

      def client_listen(arg = nil)
        set_or_return(:client_listen, arg, :kind_of => [String, Array],
                                           :default => '0.0.0.0')
      end

      def client_port(arg = nil)
        set_or_return(:client_port, arg, :kind_of => [Integer, Array],
                                         :default => 2379)
      end

      def peer_host(arg = nil)
        set_or_return(:peer_host, arg, :kind_of => [String, Array],
                                       :default => node['ipaddress'])
      end

      def peer_listen(arg = nil)
        set_or_return(:peer_listen, arg, :kind_of => [String, Array],
                                         :default => '0.0.0.0')
      end

      def peer_port(arg = nil)
        set_or_return(:peer_port, arg, :kind_of => [Integer, Array],
                                       :default => 2380)
      end

      def data_dir(arg = nil)
        set_or_return(:data_dir, arg, :kind_of => String,
                                      :default => '/var/data/etcd')
      end

      def snapshot_count(arg = nil)
        set_or_return(:snapshot_count, arg, :kind_of => Integer,
                                            :default => 10_000)
      end

      def max_snapshots(arg = nil)
        set_or_return(:max_snapshots, arg, :kind_of => Integer,
                                           :default => 5)
      end

      def max_wals(arg = nil)
        set_or_return(:max_wals, arg, :kind_of => Integer,
                                      :default => 5)
      end

      def heartbeat_interval(arg = nil)
        set_or_return(:heartbeat_interval, arg, :kind_of => Integer,
                                                :default => 100)
      end

      def election_timeout(arg = nil)
        set_or_return(:election_timeout, arg, :kind_of => Integer, :default => 1000)
      end

      def cors(arg = nil)
        set_or_return(:cors, arg, :kind_of => [String, Array], :default => [])
      end

      def proxy(arg = nil)
        set_or_return(:proxy, arg, :kind_of => Symbol,
                                   :equal_to => [:on, :readonly, :off],
                                   :default => :off)
      end

      ## SSL
      def protocol(arg = nil)
        set_or_return(:protocol, arg, :kind_of => Symbol,
                                      :equal_to => [:http, :https],
                                      :default => :http)
      end

      def cert_file(arg = nil)
        set_or_return(:cert_file, arg, :kind_of => String)
      end

      def key_file(arg = nil)
        set_or_return(:key_file, arg, :kind_of => String)
      end

      def client_cert_auth(arg = nil)
        set_or_return(:client_cert_auth, arg, :kind_of => [TrueClass, FalseClass], :default => false)
      end

      def trusted_ca_file(arg = nil)
        set_or_return(:trusted_ca_file, arg, :kind_of => String)
      end

      def peer_cert_file(arg = nil)
        set_or_return(:peer_cert_file, arg, :kind_of => String)
      end

      def peer_key_file(arg = nil)
        set_or_return(:peer_key_file, arg, :kind_of => String)
      end

      def peer_client_cert_auth(arg = nil)
        set_or_return(:peer_client_cert_auth, arg, :kind_of => [TrueClass, FalseClass], :default => false)
      end

      def peer_trusted_ca_file(arg = nil)
        set_or_return(:peer_trusted_ca_file, arg, :kind_of => String)
      end

      ## Cluster configuration
      def discovery(arg = nil)
        set_or_return(:discovery, arg, :kind_of => Symbol,
                                       :equal_to => [:static, :etcd, :dns, :aws],
                                       :default => :static)
      end

      def state(arg = nil)
        set_or_return(:state, arg, :kind_of => Symbol,
                                   :equal_to => [:new, :existing],
                                   :default => :new)
      end

      def token(arg = nil)
        set_or_return(:token, arg, :kind_of => String, :default => 'etcd-cluster')
      end

      def discovery_service(arg = nil)
        set_or_return(:discovery_service, arg, :kind_of => String)
      end

      def discovery_domain(arg = nil)
        set_or_return(:discovery_domain, arg, :kind_of => String)
      end

      def discovery_fallback(arg = nil)
        set_or_return(:discovery_fallback, arg, :kind_of => Symbol,
                                                :equal_to => [:exit, :proxy],
                                                :default => :proxy)
      end

      def discovery_proxy(arg = nil)
        set_or_return(:discovery_proxy, arg, :kind_of => String)
      end

      def aws_tags(arg = nil)
        set_or_return(:aws_tags, arg, :kind_of => Hash,
                                      :default => {
                                        :Service => 'etcd',
                                        :Cluster => node['etcd_v2']['aws_cluster']
                                      })
      end

      def quorum(arg = nil)
        set_or_return(:quorum, arg, :kind_of => Integer, :default => node['etcd_v2']['quorum'])
      end

      def aws_host_attribute(arg = nil)
        set_or_return(:aws_host_attribute, arg, :kind_of => Symbol, :default => :private_dns_name)
      end

      def aws_access_key(arg = nil)
        set_or_return(:aws_access_key, arg, :kind_of => String)
      end

      def aws_secret_access_key(arg = nil)
        set_or_return(:aws_secret_access_key, arg, :kind_of => String)
      end

      ## Define a peer node
      def peer(*args)
        ETCD::Client.new(*args).tap { |c| peers << c }
      end

      def active_peers
        peers.select(&:online?)
      end

      ## Get Chef::Resource for etcd instance
      def instance_resource
        instance.is_a?(Resource::Etcd) ? instance : resources(instance)
      end

      ## Template Helpers
      def client_advertise_urls
        ETCD::URIBuilder.url(protocol, client_host, client_port)
      end

      def client_listen_urls
        ETCD::URIBuilder.url(protocol, client_listen, client_port)
      end

      def peer_advertise_urls
        ETCD::URIBuilder.url(protocol, peer_host, peer_port)
      end

      def peer_listen_urls
        ETCD::URIBuilder.url(protocol, peer_listen, peer_port)
      end

      def peer_cluster
        cluster = peers.map { |peer| "#{ peer.name }=#{ peer.peer_url }" }

        ## Only add our self to the cluster list if we're not a proxy
        cluster += peer_advertise_urls.map { |url| "#{ node_name }=#{ url }" } if proxy == :off

        ## Remove possible duplicates after adding self to the cluster, and return it sorted.
        cluster.uniq.sort
      end
    end
  end
end
