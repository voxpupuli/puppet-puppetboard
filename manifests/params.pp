# == Class: puppetboard::params
#
# Defines default values for puppetboard parameters.
#
# Inherited by Class['puppetboard'].
#
class puppetboard::params {

  case $facts['os']['family'] {
    'Debian': {
      if ($facts['os']['name'] == 'ubuntu') {
        if (versioncmp($facts['os']['release']['full'],'14.04')) {
          $apache_confd   = '/etc/apache2/conf.d'
        } else {
          $apache_confd = '/etc/apache2/conf-enabled'
        }
      } else {
        $apache_confd   = '/etc/apache2/conf.d'
      }
      $apache_service = 'apache2'
    }

    'RedHat': {
      $apache_confd   = '/etc/httpd/conf.d'
      $apache_service = 'httpd'
      File {
        seltype => 'httpd_sys_content_t',
      }
    }
    default: { fail("The ${facts['os']['family']} operating system is not supported with the puppetboard module") }
  }

  $manage_selinux = $::selinux ? {
    false   => false,
    default => true,
  }

  $user  = 'puppetboard'
  $group = 'puppetboard'
  $basedir = '/srv/puppetboard'
  $git_source = 'https://github.com/voxpupuli/puppetboard'
  $puppetdb_host = 'localhost'
  $puppetdb_port = 8080
  $puppetdb_ssl_verify = false
  $puppetdb_timeout = 20
  $dev_listen_host = '127.0.0.1'
  $dev_listen_port = 5000
  $unresponsive = 3
  $enable_catalog = false
  $enable_query = true
  $localise_timestamp = true
  $offline_mode = false
  $python_loglevel = 'info'
  $reports_count = 10
  $experimental = false
  $virtualenv = 'python-virtualenv'
  $listen = 'private'
  $apache_override = 'None'
  $default_environment = 'production'
  $extra_settings = {}
  $enable_ldap_auth = false
}
