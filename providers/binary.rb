#
# Cookbook Name:: etcd
# Provider:: binary
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
use_inline_resources

action :install do
  remote_file "etcd-#{ new_resource.name }-github-artifact" do
    path new_resource.package_cache
    source new_resource.github_url
    action :create_if_missing
    only_if { new_resource.from.to_sym == :github }
  end

  libarchive_file "etcd-#{ new_resource.name }-temp-package" do
    path new_resource.package_cache
    extract_to new_resource.path
    extract_options [:no_overwrite]
  end

  ## Link executables to someplace in PATH
  if new_resource.bin_path.is_a?(String)
    link ::File.join(new_resource.bin_path, 'etcd') do
      to new_resource.srv_binary
    end

    link ::File.join(new_resource.bin_path, 'etcdctl') do
      to new_resource.ctl_binary
    end
  end
end
