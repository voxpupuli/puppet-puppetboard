# == Class: puppetboard
#
# Base class for Puppetboard.
# Sets up the user and python environment.
#
# You should also use one of the apache classes as well.
#
# === Parameters
#
# Document parameters here.
#
# [*user*]
#   (string) Puppetboard system user.
#   Defaults to 'puppetboard' ($::puppetboard::params::user)
#
# [*group*]
#   (string) Puppetboard system group.
#   Defaults to 'puppetboard' ($::puppetboard::params::group)
#
# [*basedir*]
#   (string) Base directory where to build puppetboard vcsrepo and python virtualenv.
#   Defaults to '/srv/puppetboard' ($::puppetboard::params::basedir)
#
# [*puppetdb_host*]
#   (string) PuppetDB Host
#   Defaults to 'localhost' ($::puppetboard::params::puppetdb_host)
#
# [*puppetdb_port*]
#   (int) PuppetDB Port
#   Defaults to 8080 ($::puppetboard::params::puppetdb_port)
#
# [*puppetdb_key*]
#   (string, absolute path) path to PuppetMaster/CA signed client SSL key
#   Defaults to 'None' ($::puppetboard::params::puppetdb_key)
#
# [*puppetdb_ssl*]
#   (string) whether PuppetDB uses SSL or not,  'True' or 'False'.
#   Defaults to 'False' ($::puppetboard::params::puppetdb_ssl)
#
# [*puppetdb_cert*]
#   (string, absolute path) path to PuppetMaster/CA signed client SSL cert
#   Defaults to 'None' ($::puppetboard::params::puppetdb_cert)
#
# [*puppetdb_timeout*]
#   (int) timeout, in seconds, for connecting to PuppetDB
#   Defaults to 20 ($::puppetboard::params::puppetdb_timeout)
#
# [*dev_listen_host*]
#   (string) host that dev server binds to/listens on
#   Defaults to '127.0.0.1' ($::puppetboard::params::dev_listen_host)
#
# [*dev_listen_port*]
#   (int) port that dev server binds to/listens on
#   Defaults to 5000 ($::puppetboard::params::dev_listen_port)
#
# [*unresponsive*]
#   (int) number of hours after which a node is considered "unresponsive"
#   Defaults to 3 ($::puppetboard::params::unresponsive)
#
# [*enable_query*]
#   (string) Whether to allow the user to run raw queries against PuppetDB. 'True' or 'False'.
#   Defaults to 'True' ($::puppetboard::params::enable_query)
#
# [*python_loglevel*]
#   (string) Python logging module log level.
#   Defaults to 'info' ($::puppetboard::params::python_loglevel)
#
# [*experimental*]
#   (string) Enable experimental features. 'True' or 'False'.
#   Defaults to true ($::puppetboard::params::experimental)
#
# === Examples
#
#  class { 'puppetboard':
#    user  => 'pboard',
#    group => 'pboard',
#    basedir => '/www/puppetboard'
#  } ->
#  class { 'puppetboard::apache::conf':
#    user  => 'pboard',
#    group => 'pboard',
#    basedir => '/www/puppetboard'
#  }
#
class puppetboard(
  $user             = $::puppetboard::params::user,
  $group            = $::puppetboard::params::group,
  $basedir          = $::puppetboard::params::basedir,

  $puppetdb_host    = $::puppetboard::params::puppetdb_host,
  $puppetdb_port    = $::puppetboard::params::puppetdb_port,
  $puppetdb_key     = $::puppetboard::params::puppetdb_key,
  $puppetdb_ssl     = $::puppetboard::params::puppetdb_ssl,
  $puppetdb_cert    = $::puppetboard::params::puppetdb_cert,
  $puppetdb_timeout = $::puppetboard::params::puppetdb_timeout,
  $unresponsive     = $::puppetboard::params::unresponsive,
  $enable_query     = $::puppetboard::params::enable_query,
  $python_loglevel  = $::puppetboard::params::python_loglevel,
  $experimental     = $::puppetboard::params::experimental,

) inherits ::puppetboard::params {

  group { $group:
    ensure => present,
  }

  user { $user:
    ensure     => present,
    shell      => '/bin/bash',
    managehome => true,
    gid        => $group,
    system     => true,
    require    => Group[$group],
  }

  file { $basedir:
    ensure   => 'directory',
    owner    => $user,
    group    => $group,
    mode     => '0755',
  }

  vcsrepo { "${basedir}/puppetboard":
    ensure   => present,
    provider => git,
    owner    => $user,
    source   => "https://github.com/nedap/puppetboard",
    require  => User[$user],
  }

  file { "${basedir}/puppetboard":
    owner   => $user,
    recurse => true,
  }

  # Template Uses:
  # - $puppetdb_host
  # - $puppetdb_port
  # - $puppetdb_ssl
  # - $puppetdb_key
  # - $puppetdb_cert
  # - $puppetdb_timeout
  # - $dev_listen_host
  # - $dev_listen_port
  # - $unresponsive
  # - $enable_query
  # - $python_loglevel
  # - $experimental
  file { 'puppetboard/default_settings.py':
    path   => "${basedir}/puppetboard/puppetboard/default_settings.py",
    owner  => $user,
    group    => $group,
    mode     => '0644',
    content  => template('puppetboard/default_settings.py.erb'),
    require => [
      File["${basedir}/puppetboard"],
      Python::Virtualenv["${basedir}/virtenv-puppetboard"]
    ],
  }

  python::virtualenv { "${basedir}/virtenv-puppetboard":
    ensure       => present,
    version      => 'system',
    requirements => "${basedir}/puppetboard/requirements.txt",
    systempkgs   => true,
    distribute   => false,
    owner        => $user,
    cwd          => "${basedir}/puppetboard",
    require      => Vcsrepo["${basedir}/puppetboard"],
  }

  if $listen == 'public' {
    file_line { 'puppetboard listen':
      path    => "${basedir}/puppetboard/dev.py",
      line    => " app.run('0.0.0.0')",
      match   => ' app.run\(\'([\d\.]+)\'\)',
      notify  => Service['puppetboard'],
      require => [
        File["${basedir}/puppetboard"],
        Python::Virtualenv["${basedir}/virtenv-puppetboard"]
      ],
    }
  }

}
