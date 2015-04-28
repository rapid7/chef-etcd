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
actions :configure
default_action :configure

attr_accessor :peers

def initialize(*_)
  super

  @peers = []
end

attribute :node_name, :name_attribute => true
attribute :instance, :kind_of => [String, Hash, Resource::Etcd],
                     :required => true

attribute :user, :kind_of => String, :default => 'etcd'
attribute :group, :kind_of => String, :default => 'etcd'
attribute :service_action, :kind_of => [Symbol, Array],
                           :equal_to => [:enable, :start, :stop, :disable],
                           :default => [:start, :enable]

## Node configuration/tuning
attribute :client_host, :kind_of => [String, Array], :default => node['ipaddress']
attribute :client_listen, :kind_of => [String, Array], :default => '0.0.0.0'
attribute :client_port, :kind_of => [Integer, Array], :default => 2379
attribute :peer_host, :kind_of => [String, Array], :default => node['ipaddress']
attribute :peer_listen, :kind_of => [String, Array], :default => '0.0.0.0'
attribute :peer_port, :kind_of => [Integer, Array], :default => 2380

attribute :data_dir, :kind_of => String, :default => '/var/data/etcd'
attribute :snapshot_count, :kind_of => Integer, :default => 10_000
attribute :max_snapshots, :kind_of => Integer, :default => 5
attribute :max_wals, :kind_of => Integer, :default => 5
attribute :heartbeat_interval, :kind_of => Integer, :default => 100
attribute :election_timeout, :kind_of => Integer, :default => 1000

attribute :cors, :kind_of => [String, Array], :default => []
attribute :proxy, :kind_of => Symbol,
                  :equal_to => [:on, :readonly, :off],
                  :default => :off

## SSL
attribute :protocol, :kind_of => Symbol,
                     :equal_to => [:http, :https],
                     :default => :http

attribute :cert_file, :kind_of => String
attribute :key_file, :kind_of => String
attribute :client_cert_auth, :kind_of => [TrueClass, FalseClass], :default => false
attribute :trusted_ca_file, :kind_of => String
attribute :peer_cert_file, :kind_of => String
attribute :peer_key_file, :kind_of => String
attribute :peer_client_cert_auth, :kind_of => [TrueClass, FalseClass], :default => false
attribute :peer_trusted_ca_file, :kind_of => String

## Cluster configuration
attribute :discovery, :kind_of => Symbol,
                      :equal_to => [:static, :etcd, :dns, :aws],
                      :default => :static
attribute :state, :kind_of => Symbol,
                  :equal_to => [:new, :existing],
                  :default => :new
attribute :token, :kind_of => String, :default => 'etcd-cluster'

attribute :discovery_service, :kind_of => String
attribute :discovery_domain, :kind_of => String
attribute :discovery_fallback, :kind_of => Symbol,
                               :equal_to => [:exit, :proxy],
                               :default => :proxy
attribute :discovery_proxy, :kind_of => String

attribute :aws_tags, :kind_of => Hash, :default => {
  :Service => 'etcd',
  :Cluster => node['etcd']['aws_cluster']
}
attribute :quorum, :kind_of => Integer, :default => node['etcd']['quorum']
attribute :aws_host_attribute, :kind_of => Symbol, :default => :private_dns_name
attribute :aws_access_key, :kind_of => String
attribute :aws_secret_access_key, :kind_of => String

## Define a peer node
def peer(*args)
  ETCD::Client.new(*args).tap { |c| peers << c }
end

def active_peers
  peers.select(&:online?)
end

## Get Chef::Resource for etcd instnace
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

  cluster.sort
end
