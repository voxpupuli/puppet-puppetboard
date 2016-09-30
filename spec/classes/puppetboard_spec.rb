require 'spec_helper'

describe 'puppetboard', type: :class do
  on_supported_os.each do |os, facts|
    let :facts do
      facts
    end
    context "on #{os}" do
      it { should compile.with_all_deps }
      it { should contain_class('puppetboard') }
      it { should contain_class('puppetboard::params') }
      it { should contain_file('/srv/puppetboard/puppetboard/settings.py') }
      it { should contain_file('/srv/puppetboard/puppetboard') }
      it { should contain_file('/srv/puppetboard') }
      it { should contain_group('puppetboard') }
      it { should contain_user('puppetboard') }
      it { should contain_python__virtualenv('/srv/puppetboard/virtenv-puppetboard') }
      it { should contain_vcsrepo('/srv/puppetboard/puppetboard') }
    end
  end
end
