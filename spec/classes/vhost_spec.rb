require 'spec_helper'

describe 'puppetboard::apache::vhost' do
  describe 'default params' do
    let :params do
      {
        'vhost_name' => 'puppetboard.local',
        'port'       => 80
      }
    end
    let(:pre_condition) do
      [
        'class { "apache": default_vhost => false, default_mods => false, }',
        'class { "apache::mod::wsgi": }',
        'class { "puppetboard": }'
      ]
    end

    on_supported_os.each do |os, facts|
      let :facts do
        facts
      end

      context "on  #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetboard::apache::vhost') }
        it { is_expected.to contain_file('/srv/puppetboard/puppetboard/wsgi.py') }
        it do
          is_expected.to contain_apache__vhost('puppetboard.local').with(
            'ensure' => 'present',
            'port'   => 80
          ).that_requires('File[/srv/puppetboard/puppetboard/wsgi.py]')
        end
        it do
          is_expected.to contain_concat('25-puppetboard.local.conf').with(
            'ensure' => 'present',
            'path'   => '/etc/apache2/sites-available/25-puppetboard.local.conf'
          )
        end
      end
    end
  end
end
