# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # Install additional modules for soft deps
  # Do not use puppetlabs-puppetdb 8.1.0, see its #412
  install_puppet_module_via_pmt_on(host, 'puppetlabs-puppetdb', '<= 8.0.1')
  install_puppet_module_via_pmt_on(host, 'puppetlabs-apache')
  install_puppet_module_via_pmt_on(host, 'puppet-epel')
end
