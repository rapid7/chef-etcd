#
# Cookbook Name:: etcd
# Library:: etcd_client
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
require 'date'
require 'json'
require 'net/http'
require 'net/https'
require 'timeout'
require 'uri'

module ETCD
  ##
  # URI Builder Helpers
  ##
  module URIBuilder
    class << self
      ## Construct a set of protocol://host:port combinations
      def url(protocol, hosts, ports)
        hosts = hosts.is_a?(Array) ? hosts : [hosts]
        ports = ports.is_a?(Array) ? ports : [ports]

        hosts.map { |host| ports.map do |port|
          uri_class(protocol).build(:host => host, :port => port)
        end }.flatten.sort_by {|uri| uri.to_s}
      end

      ## Return the correct URI class for a given protocol scheme
      def uri_class(pp = protocol)
        case pp.to_sym
        when :http then URI::HTTP
        when :https then URI::HTTPS
        else fail 'Peer protocol must be one of :http, :https'
        end
      end

      ## Return the correct URI class for a given protocol scheme
      def protocol_class(pp = protocol)
        case pp.to_sym
        when :http then Net::HTTP
        when :https then Net::HTTPS
        else fail 'Peer protocol must be one of :http, :https'
        end
      end
    end
  end

  ##
  # A peer node
  ##
  class Client
    attr_reader :name
    attr_reader :protocol
    attr_reader :host
    attr_reader :client_port
    attr_reader :peer_port
    attr_accessor :timeout

    def initialize(name, host = 'localhost', options = {})
      @name = name
      @protocol = options.fetch(:protocol, :http)
      @host = host
      @client_port = options.fetch(:client_port, 2379)
      @peer_port = options.fetch(:peer_port, 2380)
      @timeout = options.fetch(:timeout, 5)

      @leader = false
    end

    def client
      @client ||= URIBuilder.protocol_class(@protocol).new(@host, @client_port)
    end

    def request(method, path, options = {})
      args = []

      if options.include?(:body)
        args << JSON.generate(options[:body])
        args << {
          'Content-Type' => 'application/json'
        }
      end

      retries = options.fetch(:retries, 0)
      loop do
        begin
          Timeout.timeout(@timeout) do
            response = client.send(method, path, *args)

            return JSON.parse(response.body) unless response.body.empty?
            return
          end
        rescue Timeout::Error => e
          retries += -1
          raise e if retries < 0

          sleep 1
        end
      end
    end

    def peer_url
      URIBuilder.uri_class(protocol).build(:host => host, :port => peer_port)
    end

    def status
      stats = request(:get, '/v2/stats/self')

      @leader = (stats.fetch('state', '') == 'StateLeader')
      @started = DateTime.parse(stats['startTime']) if stats.include?('startTime')

      stats
    end

    def online?
      status
      true
    rescue Timeout::Error, Errno::ECONNREFUSED
      false
    end

    def leader?
      return false unless online?
      @leader
    end

    def members
      return [] unless online?
      request(:get, '/v2/members').fetch('members', [])
    end

    def join(peer)
      return unless online?
      peer = peer.is_a?(Array) ? peer : [peer]
      request(:post, '/v2/members', :retries => 12,
                                    :body => { :peerURLs => peer }).fetch('id', nil)
    end
  end
end
