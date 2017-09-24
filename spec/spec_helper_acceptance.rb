require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper
install_module
install_module_dependencies

# Install additional modules for soft deps
install_module_from_forge('puppetlabs-apache', '>= 2.1.0 < 3.0.0')
install_module_from_forge('stahnma-epel', '>= 1.2.2 < 2.0.0')

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation
end
