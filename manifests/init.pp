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
#   Puppetboard system user.
#   Defaults to 'puppetboard'
#
# [*group*]
#   Puppetboard system group.
#   Defaults to 'puppetboard'
#
# [*basedir*]
#   Base directory where to build puppetboard vcsrepo and python virtualenv.
#   Defaults to '/srv/puppetboard'
#
# [*experimental*]
#   Enable experimental features.
#   Defaults to true
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
  $user          = $::puppetboard::params::user,
  $group         = $::puppetboard::params::group,
  $basedir       = $::puppetboard::params::basedir,
  $experimental  = true,
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

  python::virtualenv { "${basedir}/virtenv-puppetboard":
    ensure       => present,
    version      => 'system',
    requirements => "${basedir}/puppetboard/requirements.txt",
    systempkgs   => true,
    distribute   => false,
    owner        => $user,
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

  if ($experimental) {
    file_line { 'puppetboard experimental':
      path    => "${basedir}/puppetboard/puppetboard/default_settings.py",
      line    => 'PUPPETDB_EXPERIMENTAL=True',
      match   => 'PUPPETDB_EXPERIMENTAL=(True|False)',
      #notify  => Service['puppetboard'],
      require => [
        File["${basedir}/puppetboard"],
        Python::Virtualenv["${basedir}/virtenv-puppetboard"]
      ],
    }
  }

}
