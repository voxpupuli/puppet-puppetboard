require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    install_module
    install_module_dependencies

    # Install additional modules for soft deps
    install_module_from_forge('puppetlabs-apache', '>= 2.1.0 < 6.0.0')
    install_module_from_forge('stahnma-epel', '>= 1.2.2 < 2.0.0')
  end
end
