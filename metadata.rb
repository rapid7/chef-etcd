name 'etcd'
maintainer 'Rapid7 LLC'
maintainer_email 'coreservices@rapid7.com'
description 'Install and configure etcd'

license IO.read('LICENSE') rescue 'All rights reserved'
long_description IO.read('README.md') rescue ''
version IO.read('VERSION') rescue '0.0.1'

depends 'apt'
depends 'libarchive', '>= 0.5.0'

recommends 'aws'
