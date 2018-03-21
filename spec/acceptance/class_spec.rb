require 'spec_helper_acceptance'

describe 'puppetboard class' do
  case fact('os.family')
  when 'RedHat'
    apache_conf_file = '/etc/httpd/conf.d/puppetboard.conf'
  when 'Debian'
    apache_conf_file = '/etc/apache2/conf-enabled/puppetboard.conf'
  end

  context 'default parameters' do
    it 'works with no errors' do
      pp = <<-EOS
      if $facts['os']['family'] == 'RedHat' {
        include epel
      }
      class { '::puppetboard':
        manage_git        => true,
        manage_virtualenv => true,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    # TODO: get this working
    # it 'should not answer to localhost' do
    #  shell("/usr/bin/curl localhost:80", :acceptable_exit_codes => 7) do |r|
    #    r.exit_code.should == 7 # curl (7): Couldn't connect to host
    #  end
    # end
  end

  context 'configuring Apache / mod_wsgi' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache':
        default_vhost => false,
        purge_configs => true,
      }
      if $facts['os']['family'] == 'RedHat' {
        include epel
        class { 'apache::mod::wsgi': wsgi_socket_prefix => '/var/run/wsgi' }
      } else {
        class { 'apache::mod::wsgi': }
      }

      # Configure Puppetboard
      class { 'puppetboard': }

      # Access Puppetboard through pboard.example.com
      class { 'puppetboard::apache::vhost':
        vhost_name => 'pboard.example.com',
        port       => 80,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'answers to localhost' do
      shell('/usr/bin/curl localhost') do |r|
        expect(r.stdout).to match(%r{Live from PuppetDB.})
        expect(r.exit_code).to be_zero
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'with SSL' do
    it 'works with no errors' do
      pp = <<-EOS
      if $facts['os']['family'] == 'RedHat' {
        include epel
      }
      # Configure Apache on this server
      class { 'apache': }
      class { 'apache::mod::wsgi': }
      class { 'puppetboard':
        manage_virtualenv => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => 8081,
        puppetdb_key  => '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem',
        puppetdb_ssl_verify => true,
        puppetdb_cert => '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem',
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

  context 'LDAP auth' do
    it 'works with no errors' do
      pp = <<-EOS
      if $facts['os']['family'] == 'RedHat' {
        include epel
      }
      # Configure Apache on this server
      class { 'apache': }
      class { 'apache::mod::wsgi': }
      class { 'apache::mod::authnz_ldap': }
      -> class { 'puppetboard':
        manage_virtualenv => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => 8081,
        puppetdb_key  => "/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem",
        puppetdb_ssl_verify => true,
        puppetdb_cert => "/var/lib/puppet/ssl/certs/test.networkninjas.net.pem",
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    describe file(apache_conf_file) do
      it { is_expected.to contain 'AuthBasicProvider ldap' }
      it { is_expected.to contain 'AuthLDAPBindDN "cn=user,dc=puppet,dc=example,dc=com"' }
      it { is_expected.to contain 'AuthLDAPURL "ldap://puppet.example.com"' }
    end
    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end
end
