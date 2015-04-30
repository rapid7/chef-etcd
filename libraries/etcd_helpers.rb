#
# Cookbook Name:: etcd
# Library:: etcd_helpers
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
module ETCD
  ##
  # Service State Helpers
  ##
  module Helpers
    ## Get a snapshot of the cluster state
    def active_peers
      @active_peers ||= new_resource.active_peers
    end

    def leader
      active_peers.select(&:leader?).first
    end

    def join_active_cluster
      cluster_member_urls = leader.members.map { |m| m.fetch('peerURLs', []) }.flatten

      Chef::Log.info("etcd_service[#{ new_resource.name }] Active cluster has "\
        "#{ cluster_member_urls.length } members #{ cluster_member_urls.join(',') } ")
      Chef::Log.info("etcd_service[#{ new_resource.name }] This node advertises " +
        new_resource.peer_advertise_urls.join(','))

      ## Do we need to join?
      my_registered_urls = (cluster_member_urls & new_resource.peer_advertise_urls.map(&:to_s))
      Chef::Log.info("etcd_service[#{ new_resource.name }] #{ my_registered_urls.length } "\
        "local peer URLs found #{ my_registered_urls.join(',') }")

      return unless my_registered_urls.empty?

      Chef::Log.info("etcd_service[#{ new_resource.name }] Registering with active cluster")
      response = leader.join(new_resource.peer_advertise_urls)
      Chef::Application.fatal!("etcd_service[#{ new_resource.name }] Unable to register with existing cluster") if response.nil?
    end

    def build_arguments
      [
        "-name #{ new_resource.node_name }",
        "-data-dir #{ new_resource.data_dir }",
        "-snapshot-count #{ new_resource.snapshot_count }",
        "-heartbeat-interval #{ new_resource.heartbeat_interval }",
        "-election-timeout #{ new_resource.election_timeout }",
        "-listen-client-urls '#{ new_resource.client_listen_urls.join(',') }'",
        "-listen-peer-urls '#{ new_resource.peer_listen_urls.join(',') }'",
        "-max-snapshots #{ new_resource.max_snapshots }",
        "-max-wals #{ new_resource.max_wals }",
        "-initial-cluster-token '#{ new_resource.token }'",
        "-advertise-client-urls '#{ new_resource.client_advertise_urls.join(',') }'",
        "-initial-advertise-peer-urls '#{ new_resource.peer_advertise_urls.join(',') }'",
        "-proxy '#{ new_resource.proxy }'"
      ].tap do |etcd_arguments|
        etcd_arguments << "-cors '#{ cors.is_a?(Array) ? cors.join(',') : cors }'" unless new_resource.cors.empty?

        ## SSL Arguments
        if new_resource.protocol.to_sym == :https
          etcd_arguments << "-cert-file #{ new_resource.cert_file }"
          etcd_arguments << "-key-file #{ new_resource.key_file }"
          etcd_arguments << "-client-cert-auth #{ new_resource.client_cert_auth }"
          etcd_arguments << "-trusted-ca-file #{ new_resource.trusted_ca_file }"
          etcd_arguments << "-peer-cert-file #{ new_resource.peer_cert_file }"
          etcd_arguments << "-peer-key-file #{ new_resource.peer_key_file }"
          etcd_arguments << "-peer-client-cert-auth #{ new_resource.peer_client_cert_auth }"
          etcd_arguments << "-peer-trusted-ca-file #{ new_resource.peer_trusted_ca_file }"
        end

        ## Discovery-specific arguments
        case new_resource.discovery
        when :static, :aws
          Chef::Log.info("etcd_service[#{ new_resource.name }] Using static discovery") unless new_resource.discovery == :aws
          etcd_arguments << "-initial-cluster '#{ new_resource.peer_cluster.join(',') }'"
          etcd_arguments << "-initial-cluster-state #{ new_resource.state }"

        when :etcd
          Chef::Application.fatal!('Attribte discovery_service is required for :etcd '\
          'cliuster discovery') if new_resource.discovery_service.nil?

          Chef::Log.info("etcd_service[#{ new_resource.name }] Using etcd discovery")
          etcd_arguments << "-discovery '#{ new_resource.discovery_service }'"
          etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
          etcd_arguments << "-discovery-proxy #{ new_resource.discovery_proxy }"

        when :dns
          Chef::Application.fatal!('Attribte discovery_domain is required for :dns '\
          'cliuster discovery') if new_resource.discovery_domain.nil?

          Chef::Log.info("etcd_service[#{ new_resource.name }] Using DNS discovery")
          etcd_arguments << "-discovery-srv '#{ new_resource.discovery_domain }'"
          etcd_arguments << "-discovery-fallback #{ new_resource.discovery_fallback }"
          etcd_arguments << "-discovery-proxy #{ new_resource.discovery_proxy }"
          etcd_arguments << "-initial-cluster-state #{ new_resource.state }"

        else fail "Discovery method #{ new_resource.discovery } is not supported! "\
          'Please select one of :static, :etcd, :dns, or :aws'
        end
      end
    end

    ## Logic to bootstrap, join, or proxy a cluster
    def autoconfigure_node
      Chef::Log.info("etcd_service[#{ new_resource.name }] Cluster leader is #{ leader.peer_url }") unless leader.nil?

      if active_peers.length >= new_resource.quorum
        ## We should become a proxy.
        Chef::Log.info("Quorum of #{ new_resource.quorum } peers already exists. Becoming a proxy.")
        new_resource.state(:existing)
        new_resource.proxy(:on)

      elsif leader.nil?
        ## This is probably a new cluster.
        Chef::Log.info("etcd_service[#{ new_resource.name }] No active leader. "\
          'Atempting to bootstrap a new cluster. Stand back, I\'m going to try something.')
        new_resource.state(:new)
        new_resource.proxy(:off)

      else
        ## There is an active leader. We should join the cluster
        Chef::Log.info("etcd_service[#{ new_resource.name }] Joining an existing cluster")
        new_resource.state(:existing)
        new_resource.proxy(:off)
        join_active_cluster
      end

      Chef::Log.info("etcd_service[#{ new_resource.name }] Setting state to #{ new_resource.state }")
      Chef::Log.info("etcd_service[#{ new_resource.name }] Setting proxy to #{ new_resource.proxy }")
    end
  end
end
