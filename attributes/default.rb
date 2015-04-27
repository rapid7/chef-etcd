
## apt configuration
include_attribute 'apt::default'
default['apt']['compile_time_update'] = true

## etcd install configuration
default['etcd']['version'] = 'v2.0.10'
default['etcd']['platform'] = 'linux-amd64'
default['etcd']['bin_repository'] = 'coreos/etcd'
default['etcd']['source_repository'] = 'git@github.com:coreos/etcd.git'

## etcd AWS configuration
default['etcd']['aws_quorum'] = 3
default['etcd']['aws_cluster'] = 'default'
