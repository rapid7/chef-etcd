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

The only required attributes in the following are `name_node` (name attribute) and `instance`. Other values have sane defaults for running a single node cluster. While most configuration parameters are exposed directly, several abstractions are provided to capture some of the more confusing or repetitive parts of the etcd v2 configuration spec:
 * `*_port`, `*_listen`, and `*_host` attributes are used to simplify the composition of various `*-url` arguments. Arrays passed to these attributes will result in geometric compositions, including the `protocol` arrtibute in the respective argument: `-advertise-client-urls http://client_host[0]:client_port[0],http://client_host[0]:client_port[1],http://client_host[1]:client_port[0],...`
 * Static peers are added using the `peer(name, protocol, host, client_port, peer_port)` method. The node's `-initial-cluster` argument will be composed from a merge of `protocol`, `host`, and `peer_port` parameters as well as the nodes own 'peer_host:peer_port' set.

The `discovery` attribute enabled different configuration arguments specific to the respecive clustering method. `:static`, `:etcd`, and `:dns` are features of etcd. The `:aws` discovery method is implemented by this cookbook. It uses the EC2 tags API to find peers for cluster bootstrapping.

```
etcd_service 'node_name' do
  node_name 'node0'       # Name attribute. etcd node name

  ## Required: Installed version of etcd to use. Can be a string/hash reference or an instance
  ## of the `etcd_binary` or `etcd_source` resource (e.g. inherits Chef::Resource::Etcd).
  instance 'etcd_binary[default]'

  ## Service operator. User/group will be created if missing. Default 'etcd'
  user 'etcd'
  group 'etcd'

  ## Passed to unterlying `service` resource
  service_action [:start, :enable]

  ## Node configuration/tuning
  client_host 'localhost' # One or more advertised client hosts (String, Array). Default `node['ipaddress']`
  client_listen '0.0.0.0' # One or more client bind addresses (String, Array). Default `0.0.0.0`
  client_port 2379        # One or more client listen ports (Integer, Array). Default 2379
  peer_host 'localhost'   # One or more advertised peer hosts. Default `node['ipaddress']`
  peer_listen             # One or more peer bind addresses. Default `0.0.0.0`
  peer_port 2380          # One or more peer listen ports. Default 2380

  ## See [The Docs](https://github.com/coreos/etcd/blob/master/Documentation/configuration.md#member-flags)
  data_dir '/var/data/etcd'
  snapshot_count 10_000
  max_snapshots 5
  max_wals 5
  heartbeat_interval 100
  election_timeout 1000

  cors 'allowed.domain.com' # CORS origins allowed by client API (String, Array).
  proxy :off              # One of :on, :readonly, :off. See [Proxy Docs](https://github.com/coreos/etcd/blob/master/Documentation/proxy.md)

  ## SSL
  protocol :http          # Listen protocol. One of :http, :https. Default :http

  ## See [The Docs](https://github.com/coreos/etcd/blob/master/Documentation/configuration.md#security-flags)
  cert_file 'client-cert.pem'
  key_file 'client-key.pem'
  client_cert_auth true
  trusted_ca_file 'client-ca.pem'
  peer_cert_file 'peer-cert.pem'
  peer_key_file 'peer-key.pem'
  peer_client_cert_auth true
  peer_trusted_ca_file 'peer-ca.pem'

  ## Cluster configuration See [The Docs])https://github.com/coreos/etcd/blob/master/Documentation/configuration.md#clustering-flags for specifics
  discovery :static       # One of :static, :etcd, :dns, :aws.
  state :new              # initial-cluster-state: One of :new, :existing. Default :new
  token 'etcd-cluster'    # initial-cluster-token: Default 'etcd-cluster'

  ## Define a peer node for :static configuration.
  peer 'node1', :http, 'localhost', 2381, 2382

  discovery_service 'https://discovery.etcd.io/blahblahblah' # An etcd discovery node
  discovery_proxy 'proxy.domain.com' # HTTP(S) Proxy to etcd discovery servuce
  discovery_domain 'domain.com' # Domain inwhich to query DNS SRV record _etcd._tcp.domain.com
  discovery_fallback :exit # One of :exit, :proxy. See [Proxy Docs](https://github.com/coreos/etcd/blob/master/Documentation/proxy.md)
end
```
