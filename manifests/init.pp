# == Class: puppetboard
#
# Full description of class puppetboard here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { puppetboard:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class puppetboard(
  $user = 'puppetboard',  # The user to run puppetboard as
  $mode = 'dev',          # also can run it under mod_wsgi
  $listen = '127.0.0.1',  # listen locally or globally
  $experimental = 'true', # enable experimental features
  $port = '5000',
  $manage_packages = 'true',
  $manage_apache_service = 'true',
) {

  class { 'python':
    version    => 'system',
    dev        => true,
    virtualenv => true,
  }

  if $manage_packages == 'true' {
    package { 'dtach':
      ensure => present,
    }
  }

  group { 'puppetboard':
    ensure => present,
  }

  user { $user:
    ensure     => present,
    home       => "/home/${user}",
    shell      => '/bin/bash',
    managehome => true,
    gid        => 'puppetboard',
    require    => Group['puppetboard'],
  }

  vcsrepo { "/home/${user}/puppetboard":
    ensure   => present,
    provider => git,
    owner    => $user,
    source   => "https://github.com/nedap/puppetboard",
    require  => User[$user],
  }

  file { "/home/${user}/puppetboard":
    owner   => $user,
    recurse => true,
  }

  python::virtualenv { "/home/${user}/virtenv-puppetboard":
    ensure       => present,
    version      => 'system',
    requirements => "/home/${user}/puppetboard/requirements.txt",
    systempkgs   => true,
    distribute   => false,
    owner        => $user,
    require      => Vcsrepo["/home/${user}/puppetboard"],
  }

  if $listen == 'public' {
    file_line { 'puppetboard listen':
      path    => "/home/${user}/puppetboard/dev.py",
      line    => " app.run('0.0.0.0')",
      match   => ' app.run\(\'([\d\.]+)\'\)',
      notify  => Service['puppetboard'],
      require => [
        File["/home/${user}/puppetboard"],
        Python::Virtualenv["/home/${user}/virtenv-puppetboard"]
      ],
    }
  }

  if $experimental == 'true' {
    file_line { 'puppetboard experimental':
      path    => "/home/${user}/puppetboard/puppetboard/default_settings.py",
      line    => 'PUPPETDB_EXPERIMENTAL=True',
      match   => 'PUPPETDB_EXPERIMENTAL=(True|False)',
      #notify  => Service['puppetboard'],
      require => [
        File["/home/${user}/puppetboard"],
        Python::Virtualenv["/home/${user}/virtenv-puppetboard"]
      ],
    }
  }

  if $mode == 'dev' {
    
    notify { "not starting puppetboard in dev mode": }

  }

  if $mode == 'wsgi' {

    case $::osfamily { 
      'Debian': { 
         $apache_root = '/etc/apache2/sites-enabled'
         $apache_service = 'apache2'
       }
      'RedHat': {
         $apache_root = '/etc/httpd/conf.d'
         $apache_service = 'httpd'
      }
      default: { fail("This module is not supported on ${::osfamily}") }
    }

    if $manage_packages == 'true' {
      package { 'libapache2-mod-wsgi': 
        ensure => present,
      }
    }


    file { "/home/${user}/puppetboard/wsgi.py":
      ensure  => present,
      content => template('puppetboard/wsgi.py.erb'),
      owner   => $user,
      group   => 'puppetboard',
      notify  => Service[$apache_service],
    }


    file { "${apache_root}/puppetboard":
      ensure  => present,
      content => template('puppetboard/puppetboard.erb'),
      owner   => $user,
      group   => 'puppetboard',
      notify  => Service[$apache_service],
    }

    if $manage_apache_service == 'true' {
       service { $apache_service:
         ensure => running, 
       }
    }
 
  }

}
