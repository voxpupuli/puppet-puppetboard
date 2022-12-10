# frozen_string_literal: true

require 'spec_helper'

describe 'puppetboard', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      # With version == 'latest' $secret_key is de facto required
      let(:params) { { 'secret_key' => 'this_should_be_a_long_secret_string', } }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppetboard') }
      it { is_expected.to contain_group('puppetboard') }
      it { is_expected.to contain_user('puppetboard') }

      if ['FreeBSD'].include?(facts[:os]['family'])
        it { is_expected.to contain_package('py39-puppetboard') }
        it { is_expected.not_to contain_file('/srv/puppetboard') }
      else
        it { is_expected.to contain_file('/srv/puppetboard/puppetboard/settings.py') }
        it { is_expected.to contain_file('/srv/puppetboard') }
        it { is_expected.to contain_python__pyvenv('/srv/puppetboard/virtenv-puppetboard') }
        it { is_expected.to contain_python__pip('puppetboard') }
      end
    end
  end
end
