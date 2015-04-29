#
# Cookbook Name:: etcd
# Library:: etcd
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
                                     :default => node['etcd_v2']['version'])
      end

      def platform(arg = nil)
        set_or_return(:platform, arg, :kind_of => String,
                                      :default => node['etcd_v2']['platform'])
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
