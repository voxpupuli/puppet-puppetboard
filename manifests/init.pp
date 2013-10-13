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
# [*experimental*]
#   Enable experimental features.
#   Defaults to true
#
# === Examples
#
#  class { 'puppetboard':
#    user  => 'pboard',
#    group => 'pboard',
#  } ->
#  class { 'puppetboard::apache::conf':
#    user  => 'pboard',
#    group => 'pboard',
#  }
#
class puppetboard(
  $user          = $::puppetboard::params::user,
  $group         = $::puppetboard::params::group,
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
    require    => Group[$group],
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

  if ($experimental) {
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

}
