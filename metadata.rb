name             'cida_auth'
maintainer       'Phethala Thongsavanh'
maintainer_email 'thongsav@usgs.gov'
license          'gplv3'
description      'Installs/Configures CIDA Auth DB/Tomcat stack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
supports         'centos'

depends 'java'
depends 'iptables'
depends 'wsi_tomcat', '>= 0.1.3'
depends 'maven'