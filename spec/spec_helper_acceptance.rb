# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # Install additional modules for soft deps
  install_puppet_module_via_pmt_on(host, 'puppetlabs-puppetdb')
  install_puppet_module_via_pmt_on(host, 'puppetlabs-apache')
  install_puppet_module_via_pmt_on(host, 'puppet-epel')
end
