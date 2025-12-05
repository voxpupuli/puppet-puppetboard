# frozen_string_literal: true

require 'spec_helper_acceptance'

require_relative 'support/puppetdb'

describe 'puppetboard class', if: has_puppetdb do
  case fact('os.family')
  when 'RedHat'
    apache_conf_file = '/etc/httpd/conf.d/25-puppetboard.conf'
  when 'Debian'
    apache_conf_file = '/etc/apache2/conf.d/25-puppetboard.conf'
  end

  context 'configuring Apache without vhost / mod_wsgi' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
      }

      # Configure Puppetboard
      class { 'puppetboard':
        manage_virtualenv => true,
        manage_git        => true,
        require           => Class['puppetdb'],
        secret_key        => 'this_should_be_a_long_secret_string',
      }

      # Configure Apache to allow access to localhost/puppetboard
      class { 'puppetboard::apache::conf': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
    end

    it 'answers to localhost' do
      shell('/usr/bin/curl localhost/puppetboard/') do |r|
        expect(r.stdout).to match(%r{<title>Puppetboard</title>})
        expect(r.exit_code).to be_zero
      end
    end
  end

  context 'configuring Apache with vhost / mod_wsgi' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache':
        default_vhost => false,
      }

      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
      }

      # Configure Puppetboard
      class { 'puppetboard':
        manage_virtualenv => true,
        manage_git        => true,
        require           => Class['puppetdb'],
        secret_key        => 'this_should_be_a_long_secret_string',
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
        expect(r.stdout).to match(%r{<title>Puppetboard</title>})
        expect(r.exit_code).to be_zero
      end
    end
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
        secret_key => 'this_should_be_a_long_secret_string',
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
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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

  context 'AUTH ldap-user' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
        ldap_require_user => 'admin1uid admin2uid',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
      it { is_expected.to contain 'Require ldap-user admin1uid admin2uid' }
    end

    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end

  context 'AUTH ldap-dn' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
        ldap_require_dn => 'cn=admin,o=example',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
      it { is_expected.to contain 'Require ldap-dn cn=admin,o=example' }
    end

    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end

  context 'AUTH ldap-attribute' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
        ldap_require_attribute => 'role=admin status=active',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
      it { is_expected.to contain 'Require ldap-attribute role=admin status=active' }
    end

    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end

  context 'AUTH ldap-filter' do
    it 'works with no errors' do
      pp = <<-EOS
      # Configure Apache on this server
      class { 'apache': }
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
        secret_key => 'this_should_be_a_long_secret_string',
      }
      class { 'puppetboard::apache::conf':
        enable_ldap_auth => true,
        ldap_bind_dn => 'cn=user,dc=puppet,dc=example,dc=com',
        ldap_bind_password => 'password',
        ldap_url     => 'ldap://puppet.example.com',
        ldap_require_filter => '&(role=sysadmin)(memberOf=g:puppetboard::ag:*)',
      }
      # Configure PuppetDB
      class { 'puppetdb':
        puppetdb_package => 'openvoxdb', # Workaround waiting for puppet-openvoxdb
        disable_ssl      => true,
        manage_firewall  => false,
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
      it { is_expected.to contain 'Require ldap-filter &(role=sysadmin)(memberOf=g:puppetboard::ag:*)' }
    end

    describe file('/srv/puppetboard/puppetboard/settings.py') do
      it { is_expected.to contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { is_expected.to contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end
  end
end
