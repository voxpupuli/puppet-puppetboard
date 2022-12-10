# frozen_string_literal: true

require 'spec_helper'

describe 'puppetboard::apache::conf' do
  describe 'default params' do
    let :params do
      {
      }
    end
    let(:pre_condition) do
      [
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
        it { is_expected.to contain_class('apache::mod::wsgi') }
      end
    end
  end
end
