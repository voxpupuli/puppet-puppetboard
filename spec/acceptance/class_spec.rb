require 'spec_helper_acceptance'

describe 'puppetboard class' do
  case fact('os.family')
  when 'RedHat'
    apache_conf_file = '/etc/httpd/conf.d/puppetboard.conf'
  when 'Debian'
    apache_conf_file = '/etc/apache2/conf-enabled/puppetboard.conf'
  end

  context 'configuring Apache without vhost / mod_wsgi' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
      $wsgi = $facts['os']['family'] ? {
        'Debian' => {package_name => "libapache2-mod-wsgi-py3", mod_path => "/usr/lib/apache2/modules/mod_wsgi.so"},
        default  => {},
      }
      class { 'apache::mod::wsgi':
        * => $wsgi,
      }

      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl     => true,
        manage_firewall => false,
      }

      # Configure Puppetboard
      class { 'puppetboard':
        manage_virtualenv => true,
        manage_git        => true,
        require           => Class['puppetdb'],
      }

      # Access Puppetboard through pboard.example.com
      class { 'puppetboard::apache::conf': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end
    it 'answers to localhost' do
      shell('/usr/bin/curl localhost/puppetboard/') do |r|
        # The default puppetboard page returns 404 on empty puppetdb
        # https://github.com/voxpupuli/puppetboard/issues/515
        expect(r.stdout).to match(%r{404 Not Found})
        expect(r.exit_code).to be_zero
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'configuring Apache with vhost / mod_wsgi' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache':
        default_vhost => false,
        purge_configs => true,
      }
      $wsgi = $facts['os']['family'] ? {
        'Debian' => {package_name => "libapache2-mod-wsgi-py3", mod_path => "/usr/lib/apache2/modules/mod_wsgi.so"},
        default  => {},
      }
      class { 'apache::mod::wsgi':
        * => $wsgi,
      }

      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl     => true,
        manage_firewall => false,
      }

      # Configure Puppetboard
      class { 'puppetboard':
        manage_virtualenv => true,
        manage_git        => true,
        require           => Class['puppetdb'],
      }

      # Access Puppetboard through pboard.example.com
      class { 'puppetboard::apache::vhost':
        vhost_name => 'localhost',
        port       => 80,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end
    it 'answers to localhost' do
      shell('/usr/bin/curl localhost') do |r|
        # The default puppetboard page returns 404 on empty puppetdb
        # https://github.com/voxpupuli/puppetboard/issues/515
        expect(r.stdout).to match(%r{404 Not Found})
        expect(r.exit_code).to be_zero
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context 'with SSL' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
      class { 'apache::mod::wsgi': }
      class { 'puppetboard':
        manage_virtualenv => true,
        manage_git => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => 8081,
        puppetdb_key  => '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem',
        puppetdb_ssl_verify => true,
        puppetdb_cert => '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem',
        require => Class['puppetdb'],
      }
      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl => true,
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

  context 'LDAP auth' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
      class { 'apache::mod::wsgi': }
      class { 'apache::mod::authnz_ldap': }
      -> class { 'puppetboard':
        manage_virtualenv => true,
        manage_git => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => 8081,
        puppetdb_key  => "/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem",
        puppetdb_ssl_verify => true,
        puppetdb_cert => "/var/lib/puppet/ssl/certs/test.networkninjas.net.pem",
        require => Class['puppetdb'],
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl => true,
        manage_firewall => false,
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

  context 'AUTH ldap-group' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
      class { 'apache::mod::wsgi': }
      class { 'apache::mod::authnz_ldap': }
      -> class { 'puppetboard':
        manage_virtualenv => true,
        manage_git => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => 8081,
        puppetdb_key  => "/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem",
        puppetdb_ssl_verify => true,
        puppetdb_cert => "/var/lib/puppet/ssl/certs/test.networkninjas.net.pem",
        require => Class['puppetdb'],
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
        ldap_require_group => true,
        ldap_require_group_dn => 'cn=admins,=cn=groups,dc=puppet,dc=example,dc=com',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        disable_ssl => true,
        manage_firewall => false,
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
      it { is_expected.to contain 'Require ldap-group cn=admins,=cn=groups,dc=puppet,dc=example,dc=com' }
    end
    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end
end
