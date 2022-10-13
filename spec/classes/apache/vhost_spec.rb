# frozen_string_literal: true

require 'spec_helper'

describe 'puppetboard::apache::vhost' do
  describe 'default params' do
    let :params do
      {
        'vhost_name' => 'puppetboard.local',
        'port' => 80,
        'enable_ldap_auth' => true
      }
    end
    let(:pre_condition) do
      [
        'class { "apache":
          default_vhost => false,
          default_mods  => false,
        }',
        'class { "puppetboard":
           secret_key => "this_should_be_a_long_secret_string",
         }'
      ]
    end

    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let :facts do
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetboard::apache::vhost') }
        it { is_expected.to contain_class('apache::mod::wsgi') }
        it { is_expected.to contain_file('/srv/puppetboard/puppetboard/wsgi.py') }

        it do
          expect(subject).to contain_apache__vhost('puppetboard.local').with(
            'ensure' => 'present',
            'port' => 80
          ).that_requires('File[/srv/puppetboard/puppetboard/wsgi.py]')
        end

        it do
          expect(subject).to contain_file('puppetboard-ldap.part').with(
            'ensure' => 'file'
          )
        end

        if ['RedHat'].include?(facts[:os]['family']) && facts[:os]['release']['major'] == '8'
          ['3.6', '3.8', '3.9'].each do |python_version|
            context "with python_versions #{python_version}" do
              let(:pre_condition) do
                [
                  "class { 'puppetboard':
                    python_version => \"#{python_version}\",
                    secret_key     => 'this_should_be_a_long_secret_string',
                  }"
                ]
              end

              case python_version
              when '3.6'
                package_name = 'python3-mod_wsgi'
              when '3.8'
                package_name = 'python38-mod_wsgi'
              when '3.9'
                package_name = 'python39-mod_wsgi'
              end

              it { is_expected.to contain_class('apache::mod::wsgi').with(package_name: package_name) }
            end
          end

          context 'with unsupported python_versions' do
            let(:pre_condition) do
              [
                "class { 'puppetboard':
                  python_version => '3.7',
                  secret_key     => 'this_should_be_a_long_secret_string',
                }
                "
              ]
            end

            it { is_expected.to raise_error(Puppet::Error, %r{python version not supported}) }
          end
        end
      end
    end
  end
end
