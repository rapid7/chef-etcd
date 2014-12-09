name 'rapid7-cookbook'
maintainer 'Rapid7 LLC'
maintainer_email 'coreservices@rapid7.com'
description 'Template for Rapid7 cookbooks'

license IO.read('LICENSE') rescue 'All rights reserved'
long_description IO.read('README.md') rescue ''
version IO.read('VERSION') rescue '0.0.1'

depends 'apt'
depends 'rapid7-baker'

fail 'This cookbook is a template. It has no executable functionality,'\
' and should not be uploaded to a chef-server or vendored for baking!'
