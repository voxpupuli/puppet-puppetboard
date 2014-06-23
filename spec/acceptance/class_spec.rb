require 'spec_helper_acceptance'
require 'pry'

describe 'puppetboard class' do

  context 'default parameters' do
    hosts.each do |host|
      if fact('osfamily') == 'RedHat'
        if fact('architecture') == 'amd64'
          on host, "wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        else
          on host, "wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        end
      end
      on host, "puppet module install puppetlabs/apache"
      install_package host, 'python-virtualenv'
      install_package host, 'git'
    end

    it 'should work with no errors' do
      pp = " class { 'puppetboard': } "

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_failures => true)
    end

    #it 'should not answer to localhost' do
    #  shell("/usr/bin/curl localhost:80", :acceptable_exit_codes => 7) do |r|
    #    r.exit_code.should == 7 # curl (7): Couldn't connect to host
    #  end
    #end

  end

  context 'default parameters' do
    hosts.each do |host|
      if fact('osfamily') == 'RedHat'
        if fact('architecture') == 'amd64'
          on host, "wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        else
          on host, "wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        end
      end
      on host, "puppet module install puppetlabs/apache"
      install_package host, 'python-virtualenv'
      install_package host, 'git'
    end

    it 'should work with no errors' do
      pp= <<-EOS
      # Configure Apache on this server
      class { 'apache':
        default_vhost => false,
        purge_configs => true,
      }
      class { 'apache::mod::wsgi': }

      # Configure Puppetboard
      class { 'puppetboard': }

      # Access Puppetboard through pboard.example.com
      class { 'puppetboard::apache::vhost':
        vhost_name => 'pboard.example.com',
      }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_failures => true)
    end

    #binding.pry

    it 'should answer to localhost' do
      shell("/usr/bin/curl localhost:5000") do |r|
        r.stdout.should =~ /niele Sluijters/
        r.exit_code.should == 0
      end
    end
  end

  context 'default parameters' do
    hosts.each do |host|
      if fact('osfamily') == 'RedHat'
        if fact('architecture') == 'amd64'
          on host, "wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        else
          on host, "wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm"
        end
      end
      on host, "puppet module install puppetlabs/apache"
      install_package host, 'python-virtualenv'
      install_package host, 'git'
    end

    it 'should work with no errors' do
      pp= <<-EOS
      class { 'puppetboard':
        manage_virtualenv => true,
        puppetdb_host => 'puppet.example.com',
        puppetdb_port => '8081',
        puppetdb_key  => "/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem",
        puppetdb_ssl  => 'True',
        puppetdb_cert => "/var/lib/puppet/ssl/certs/test.networkninjas.net.pem",
      }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_failures => true)
    end

    #binding.pry

    describe file("/srv/puppetboard/puppetboard/settings.py") do
      it { should contain "PUPPETDB_KEY = '/var/lib/puppet/ssl/private_keys/test.networkninjas.net.pem'" }
      it { should contain "PUPPETDB_CERT = '/var/lib/puppet/ssl/certs/test.networkninjas.net.pem'" }
    end

  end
end



