require 'spec_helper'

describe 'puppetboard::apache::conf' do
  describe 'default params' do
    let :params do
      {
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
      context "on  #{os}" do
        let :facts do
          facts
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
