#
# Cookbook Name:: etcd
# Library:: etcd_source
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
require_relative './etcd'

class Chef
  class Resource
    ##
    # An installation of etcd from source
    ##
    class EtcdSource < Etcd
      def initialize(name, run_context = nil)
        super

        @provider = Chef::Provider::EtcdV2Source
        @resource_name = :etcd_source
      end

      def url(arg = nil)
        set_or_return(:url, arg, :kind_of => String,
                                 :default => node['etcd_v2']['source_repository'])
      end

      def srv_binary
        ::File.join(cannonical_path, 'bin', srv_bin)
      end

      def ctl_binary
        ::File.join(cannonical_path, 'bin', ctl_bin)
      end
    end
  end
end
