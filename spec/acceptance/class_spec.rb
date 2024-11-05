# frozen_string_literal: true

require 'spec_helper_acceptance'

require_relative 'support/puppetdb'

describe 'puppetboard class', if: has_puppetdb do
  context 'with SSL' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'puppetboard':
        manage_virtualenv   => true,
        manage_git          => true,
        puppetdb_host       => 'puppet.example.com',
        puppetdb_port       => 8081,
        puppetdb_key        => '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem',
        puppetdb_ssl_verify => true,
        puppetdb_cert       => '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem',
        require             => Class['puppetdb'],
        secret_key          => 'this_should_be_a_long_secret_string',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl     => true,
        manage_firewall => false,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end
end
