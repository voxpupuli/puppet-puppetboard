require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # Install additional modules for soft deps
  install_module_from_forge_on(host, 'puppetlabs-apache', '>= 2.1.0 < 7.0.0')
  install_module_from_forge_on(host, 'puppetlabs-puppetdb', '>= 7.6.0 < 8.0.0')
  install_module_from_forge_on(host, 'puppet-epel', '>= 3.0.0 < 4.0.0')
end
