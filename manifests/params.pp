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

}
