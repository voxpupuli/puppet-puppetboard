# frozen_string_literal: true

def has_puppetdb
  case host_inventory['facter']['os']['name']
  when 'Debian'
    return false if ENV['BEAKER_PUPPET_COLLECTION'] == 'puppet6' && host_inventory['facter']['os']['release']['major'] == '11'
  end

  true
end
