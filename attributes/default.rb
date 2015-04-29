#
# Cookbook Name:: etcd
# Attributes:: default
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

## apt configuration
include_attribute 'apt::default'
default['apt']['compile_time_update'] = true

## etcd install configuration
default['etcd_v2']['version'] = 'v2.0.10'
default['etcd_v2']['platform'] = 'linux-amd64'
default['etcd_v2']['bin_repository'] = 'coreos/etcd'
default['etcd_v2']['source_repository'] = 'git@github.com:coreos/etcd.git'

## etcd AWS configuration
default['etcd_v2']['quorum'] = 3
default['etcd_v2']['aws_cluster'] = 'default'
