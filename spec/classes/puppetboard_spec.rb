# frozen_string_literal: true

require 'spec_helper'

describe 'puppetboard', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let(:params) do
        {
          'extra_settings' => {
            'DAILY_REPORTS_CHART_DAYS' => 14,
            'GRAPH_FACTS' => %w[
              apache_version
              apt_has_updates
            ],
          },
          # With version == 'latest' $secret_key is de facto required
          'secret_key' => 'this_should_be_a_long_secret_string',
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('puppetboard') }
      it { is_expected.to contain_group('puppetboard') }
      it { is_expected.to contain_user('puppetboard') }

      if ['FreeBSD'].include?(facts[:os]['family'])
        it { is_expected.to contain_package('py311-puppetboard') }
        it { is_expected.not_to contain_file('/srv/puppetboard') }
      else
        it { is_expected.to contain_file('/srv/puppetboard/puppetboard/settings.py').with(content: <<~SETTINGS) }
          # THIS FILE IS MANAGED BY PUPPET
          # DO NOT EDIT MANUALLY!
          LOGLEVEL = "info"
          PUPPETDB_HOST = "127.0.0.1"
          PUPPETDB_PORT = 8080
          PUPPETDB_SSL_VERIFY = False
          PUPPETDB_TIMEOUT = 20
          UNRESPONSIVE_HOURS = 3
          ENABLE_CATALOG = False
          ENABLE_QUERY = True
          LOCALISE_TIMESTAMP = True
          OFFLINE_MODE = False
          DEFAULT_ENVIRONMENT = "production"
          REPORTS_COUNT = 10
          SECRET_KEY = "this_should_be_a_long_secret_string"
          QUERY_PRESETS_FILE = None
          DAILY_REPORTS_CHART_DAYS = 14
          GRAPH_FACTS = ["apache_version", "apt_has_updates"]
        SETTINGS
        it { is_expected.to contain_file('/srv/puppetboard') }
        it { is_expected.to contain_python__pyvenv('/srv/puppetboard/virtenv-puppetboard') }
        it { is_expected.to contain_python__pip('puppetboard') }
      end
    end
  end
end
