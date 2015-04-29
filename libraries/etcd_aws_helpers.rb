#
# Cookbook Name:: etcd
# Library:: etcd_aws_helpers
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
  module AWSHelpers
    ## Search for peers via the AWS/EC2 API
    def aws_find_peers
      new_resource.peers = [] # Empty the peer set

      tags = new_resource.aws_tags.map do |key, value|
        {
          :name => "tag:#{ key }",
          :values => value.is_a?(Array) ? value : [value]
        }
      end

      ec2.describe_instances(:filters => tags).data.reservations
        .map(&:instances).flatten
        .reject do |instance|
          instance.instance_id == new_resource.node_name ||
            instance[new_resource.aws_host_attribute].nil? ||
            instance[new_resource.aws_host_attribute].empty?
        end.each do |instance|
          peer = new_resource.peer(instance.instance_id, instance[new_resource.aws_host_attribute],
                            :protocol => new_resource.protocol,
                            :client_port => new_resource.client_port,
                            :peer_port => new_resource.peer_port)

          Chef::Log.info("etcd_service[#{ new_resource.name }] Found peer #{ peer.name }: "\
            "#{ peer.peer_url } (active: #{ peer.online? })")
        end
    end

    ## Wait for a quorum of peers to tag temselves
    def aws_wait_for_peers
      loop do
        aws_find_peers

        Chef::Log.info("etcd_service[#{ new_resource.name }] Found "\
          "#{ new_resource.peers.length + 1 }/#{ new_resource.quorum } AWS "\
          "peers, #{ active_peers.length } active")

        break if new_resource.peers.length >= (new_resource.quorum - 1)
        break if active_peers.length > 0
        sleep 5
      end
    end

    ## Tag this instance and wait for a quorum of peers
    def aws_discovery_bootstrap
      Chef::Log.info("etcd_service[#{ new_resource.name }] Setting node_name to #{ node['ec2']['instance_id'] }")
      new_resource.node_name(node['ec2']['instance_id'])
      new_resource.client_host(node['ec2']['local_hostname'])
      new_resource.peer_host(node['ec2']['local_hostname'])

      ## Set our own tags _before_ waiting for peers.
      tag_resource = aws_resource_tag(node['ec2']['instance_id'])
      tag_resource.tags new_resource.aws_tags
      tag_resource.run_action(:update)
      tag_resource.action(:nothing)

      aws_wait_for_peers
    end
  end
end
