# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # Install additional modules for soft deps
  install_module_from_forge_on(host, 'puppetlabs-apache', '>= 8.2.1 < 9.0.0')
  install_module_from_forge_on(host, 'puppetlabs-puppetdb', '>= 7.10.0 < 8.0.0')
  install_module_from_forge_on(host, 'puppet-epel', '>= 4.1.0 < 5.0.0')
end
