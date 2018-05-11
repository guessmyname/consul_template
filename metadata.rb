name             'consul_template'
maintainer       'Vision Critical Inc. http://www.visioncritical.com'
maintainer_email 'Riley Shott <riley.shott@visioncritical.com>'
license          'MIT'
description      'Installs/Configures consul_template'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.99'

supports 'ubuntu', '>= 12.04'
supports 'redhat', '>= 6.4'
supports 'centos', '>= 6.4'
supports 'windows'
supports 'freebsd'

depends 'poise', '~> 2.6'
depends 'poise-service', '~> 1.1'
depends 'poise-archive', '~> 1.3.0'
depends 'nssm', '~> 4.0'

source_url 'https://github.com/visioncritical/consul_template' if respond_to?(:source_url)
issues_url 'https://github.com/visioncritical/consul_template/issues' if respond_to?(:issues_url)
