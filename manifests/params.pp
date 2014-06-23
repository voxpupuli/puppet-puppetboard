# == Class: puppetboard::params
#
# Defines default values for puppetboard parameters.
#
# Inherited by Class['puppetboard'].
#
class puppetboard::params {

  case $::osfamily {
    'Debian': {
      $apache_confd   = '/etc/apache2/conf.d'
      $apache_service = 'apache2'
    }
    'RedHat': {
      $apache_confd   = '/etc/httpd/conf.d'
      $apache_service = 'httpd'
    }
  }

  $user  = 'puppetboard'
  $group = 'puppetboard'
  $basedir = '/srv/puppetboard'
  $git_source = 'https://github.com/nedap/puppetboard'

  $puppetdb_host = 'localhost'
  $puppetdb_port = 8080
  $puppetdb_key = undef
  $puppetdb_ssl = false
  $puppetdb_cert = undef
  $puppetdb_timeout = 20
  $dev_listen_host = '127.0.0.1'
  $dev_listen_port = 5000
  $unresponsive = 3
  $enable_query = true
  $localise_timestamp = true
  $python_loglevel = 'info'
  $python_proxy = false
  $reports_count = '10'
  $experimental = false
  $revision = undef
  $virtualenv = 'python-virtualenv'
}
