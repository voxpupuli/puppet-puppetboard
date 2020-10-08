# == Class: puppetboard::params
#
# Defines default values for puppetboard parameters.
#
# Inherited by Class['puppetboard'].
#
class puppetboard::params {
  case $facts['os']['family'] {
    'Debian': {
      $apache_confd = '/etc/apache2/conf-enabled'
      $apache_service = 'apache2'
    }

    'RedHat': {
      $apache_confd   = '/etc/httpd/conf.d'
      $apache_service = 'httpd'
      File {
        seltype => 'httpd_sys_content_t',
      }
    }
    'Suse': {
      $apache_confd   = '/etc/apache2/conf.d'
      $apache_service = 'apache2'
    }
    default: { fail("The ${facts['os']['family']} operating system is not supported with the puppetboard module") }
  }

  case $facts['os']['name'] {
    'Debian': {
      $python_version = $facts['os']['release']['major'] ? {
        '9'  => '3.5',
        '10' => '3.7',
        '11' => '3.8',
      }
    }
    'Ubuntu': {
      $python_version = $facts['os']['release']['major'] ? {
        '16.04' => '3.5',
        '18.04' => '3.6',
        '20.04' => '3.8',
      }
    }
    'CentOS','RedHat': {
      $python_version = $facts['os']['release']['major'] ? {
        '7' => '3.6',
        '8' => '3.8',
      }
    }
    default: {
      fail("puppet/puppetboard: At the moment only Debian, Ubuntu and CentOS/RedHat are supported, not ${facts['os']['name']} in Version ${facts['os']['release']['full']}")
    }
  }
  $manage_selinux = fact('os.selinux.enabled') ? {
    true   => true,
    default => false,
  }
}
