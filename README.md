etcd Cookbook
=============
This cookbook manages [etcd](https://github.com/coreos/etcd) version 2. It provides resources for installation from both binaries and source, and for management of one or more etcd service instnaces.

## What even is all of this for?!
This cookbook aims to provide a feature complete utility to install and configure one or more instances of etcd for both production and development/testing proposes.

The `etcd_service` resource allows multiple etcd processes to run on the same system to:
 * Test client libraries with actual clusters. Not just the one node you `brew install`d and started in another terminal.
 * Test discovery configurations and failovers _before_ doing it live.
 * Figure out how to actually add/remove nodes to/from your cluster safely before you [do this](https://twitter.com/honest_update/status/591293366245163008).

Similarly, the `etcd_binary` and `etcd_source` resources ensure that their respecitve installations are vendored so as to allow mutliple versions/builds of etcd to coexist on a single system. `etcd_service` resources each map to an installation, allowing you to test arbitrary compatability scenarios both within a cluster and with client libraries.

## Resources
### etcd_binary
Install etcd from a compiled release, by default from coreos/etcd on GitHub.

`etcd_binary 'default'` will install etcd in `/opt` and link to `etcd` and `etcdctl` from `/usr/local/bin`.

```
etcd_binary 'name' do
  version 'v2.0.10'       # Default set in node['etcd']['version'], currently 'v2.0.10'
  platform 'linux-amd64'  # Default set in node['etcd']['platform']
  path '/opt'             # Install root. Unpacked into <path>/etcd-<version>-<platform>-<name>
  srv_bin 'etcd'          # Name of etcd binary
  ctl_bin 'etcdctl'       # Name of etcd control binary
  bin_path '/usr/local/bin' # Path to link to binaries from. Set to nil or false to disable linking
  from :github            # Package source. Currently only :github is supported
  repository '/coreos/etcd' # GitHub repo to fetch release from. Default node['etcd']['bin_repository']
end
```

### etcd_source
Fetch and build etcd from a git repository. This resource does not install golang. The [golang cookbook](https://supermarket.chef.io/cookbooks/golang) should do the needful for you.

```
etcd_source 'name' do
  version 'v2.0.10'       # Default set in node['etcd']['version'], currently 'v2.0.10'
  platform 'linux-amd64'  # Default set in node['etcd']['platform']
  path '/opt'             # Install root. Unpacked into <path>/etcd-<version>-<platform>-<name>
  srv_bin 'etcd'          # Name of etcd binary
  ctl_bin 'etcdctl'       # Name of etcd control binary
  bin_path '/usr/local/bin' # Path to link to binaries from. Set to nil or false to disable linking
  repository 'git@github.com:coreos/etcd.git' # Git repo to fetch source from. Default node['etcd']['source_repository']
end
```

### etcd_service
Configure and run an installation (`etcd_binary` or `etcd_source`) as a service.

```
etcd_service 'node_name' do
  
end
```
