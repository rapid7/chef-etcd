require 'json'
require 'net/http'
require 'net/https'
require 'uri'

actions :configure
default_action :configure

attr_reader :peers

def initialize(*_)
  super
  @peers = {}
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
                               :default => :exit
attribute :discovery_proxy, :kind_of => String

## HTTP/HTTPS helpers
def uri_class(pp = protocol)
  case pp.to_sym
  when :http then URI::HTTP
  when :https then URI::HTTPS
  else fail 'Peer protocol must be one of :http, :https'
  end
end

def http_class(pp = protocol)
  case pp.to_sym
  when :http then Net::HTTP
  when :https then Net::HTTPS
  else fail 'Peer protocol must be one of :http, :https'
  end
end

## Define a peer node
def peer(name, protocol = :http, host = 'localhost', client = 2379, peer = 2380)
  peers[name] = {
    :client => uri_class(protocol).build(:host => host, :port => client),
    :peer => uri_class(protocol).build(:host => host, :port => peer)
  }
end

def client
  peer = peers.values.firss[:client] ## Connect to a peer's API
  @etcd_client ||= http_class.new(peer.host, peer.port)
end

def members
  JSON.parse(client.get('/v2/members').body)
end

def join
  client.post('/v2/members', JSON.generate(:peerURLs => advertise_clients))
end

## Get Chef::Resource for etcd instnace
def instance_resource
  instance.is_a?(Resource::Etcd) ? instance : resources(instance)
end

## Template Helpers
def advertise_clients
  (client_host.is_a?(Array) ? client_host : [client_host]).map do |host|
    (client_port.is_a?(Array) ? client_port : [client_port]).map do |port|
      uri_class(protocol).build(:host => host, :port => port)
    end
  end.flatten
end

def listen_clients
  (client_listen.is_a?(Array) ? client_listen : [client_listen]).map do |host|
    (client_port.is_a?(Array) ? client_port : [client_port]).map do |port|
      uri_class(protocol).build(:host => host, :port => port)
    end
  end.flatten
end

def advertise_peers
  (peer_host.is_a?(Array) ? peer_host : [peer_host]).map do |host|
    (peer_port.is_a?(Array) ? peer_port : [peer_port]).map do |port|
      uri_class(protocol).build(:host => host, :port => port)
    end
  end.flatten
end

def listen_peers
  (peer_listen.is_a?(Array) ? peer_listen : [peer_listen]).map do |host|
    (peer_port.is_a?(Array) ? peer_port : [peer_port]).map do |port|
      uri_class(protocol).build(:host => host, :port => port)
    end
  end.flatten
end

def cluster_nodes
  (advertise_peers.map { |addr| "#{ node_name }=#{ addr }" } +
   peers.map { |n, peer| "#{ n }=#{ peer[:peer] }" }).sort.join(',')
end
