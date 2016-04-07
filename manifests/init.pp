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
# [*groups*]
#   (string) The groups to which the user belongs. The primary group should
#   not be listed, and groups should be identified by name rather than by GID.
#   Multiple groups should be specified as an array.
#   Defaults to undef ($::puppetboard::params::groups)
#
# [*basedir*]
#   (string) Base directory where to build puppetboard vcsrepo and python virtualenv.
#   Defaults to '/srv/puppetboard' ($::puppetboard::params::basedir)
#
# [*git_source*]
#   (string) Location of upstream Puppetboard GIT repository
#   Defaults to 'https://github.com/voxpupuli/puppetboard' ($::puppetboard::params::git_source)
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
# [*puppetdb_ssl_verify*]
#   (bool, string) whether PuppetDB uses SSL or not (true or false), or the path to the puppet CA
#   Defaults to false ($::puppetboard::params::puppetdb_ssl_verify)
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
# [*enable_catalog*]
#   (bool) Whether to allow the user to browser catalog comparisons.
#   Defaults to 'False' ($::puppetboard::params::enable_catalog)
#
# [*enable_query*]
#   (bool) Whether to allow the user to run raw queries against PuppetDB.
#   Defaults to 'True' ($::puppetboard::params::enable_query)
#
# [*localise_timestamp*]
#   (bool) Whether to localise the timestamps in the UI.
#   Defaults to 'True' ($::puppetboard::params::localise_timestamp)
#
# [*python_loglevel*]
#   (string) Python logging module log level.
#   Defaults to 'info' ($::puppetboard::params::python_loglevel)
#
# [*python_proxy*]
#   (string) HTTP proxy server to use for pip/virtualenv.
#   Defaults to false ($::puppetboard::params::python_proxy)
#
# [*experimental*]
#   (bool) Enable experimental features.
#   Defaults to false ($::puppetboard::params::experimental)
#
# [*revision*]
#   (string) Commit, tag, or branch from Puppetboard's Git repo to be used
#   Defaults to undef, meaning latest commit will be used ($::puppetboard::params::revision)
#
# [*manage_git*]
#   (bool) If true, require the git package. If false do nothing.
#   Defaults to false
#
# [*manage_virtualenv*]
#   (bool) If true, require the virtualenv package. If false do nothing.
#   Defaults to false
#
# [*manage_user*]
#   (bool) If true, manage (create) this group. If false do nothing.
#   Defaults to true
#
# [*manage_group*]
#   (bool) If true, manage (create) this group. If false do nothing.
#   Defaults to true
#
# [*manage_selinux*]
#   (bool) If true, manage selinux policies for puppetboard. If false do nothing.
#   Defaults to true if selinux is enabled
#
# [*reports_count*]
#   (int) This is the number of reports that we want the dashboard to display.
#   Defaults to 10
#
# [*listen*]
#   (string) Defaults to 'private' If set to 'public' puppetboard will listen
#   on 0.0.0.0; otherwise it will only be accessible via localhost.
#
# [*extra_settings*]
#   (hash) Defaults to an empty hash '{}'. Used to pass in arbitrary key/value
#   pairs that are added to settings.py
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
  $user                = $::puppetboard::params::user,
  $group               = $::puppetboard::params::group,
  $groups              = $::puppetboard::params::groups,
  $basedir             = $::puppetboard::params::basedir,
  $git_source          = $::puppetboard::params::git_source,
  $dev_listen_host     = $::puppetboard::params::dev_listen_host,
  $dev_listen_port     = $::puppetboard::params::dev_listen_port,
  $puppetdb_host       = $::puppetboard::params::puppetdb_host,
  $puppetdb_port       = $::puppetboard::params::puppetdb_port,
  $puppetdb_key        = $::puppetboard::params::puppetdb_key,
  $puppetdb_ssl_verify = $::puppetboard::params::puppetdb_ssl_verify,
  $puppetdb_cert       = $::puppetboard::params::puppetdb_cert,
  $puppetdb_timeout    = $::puppetboard::params::puppetdb_timeout,
  $unresponsive        = $::puppetboard::params::unresponsive,
  $enable_catalog      = $::puppetboard::params::enable_catalog,
  $enable_query        = $::puppetboard::params::enable_query,
  $localise_timestamp  = $::puppetboard::params::localise_timestamp,
  $python_loglevel     = $::puppetboard::params::python_loglevel,
  $python_proxy        = $::puppetboard::params::python_proxy,
  $experimental        = $::puppetboard::params::experimental,
  $revision            = $::puppetboard::params::revision,
  $manage_selinux      = $::puppetboard::params::manage_selinux,
  $manage_user         = true,
  $manage_group        = true,
  $manage_git          = false,
  $manage_virtualenv   = false,
  $reports_count       = $::puppetboard::params::reports_count,
  $listen              = $::puppetboard::params::listen,
  $extra_settings      = $::puppetboard::params::extra_settings,
) inherits ::puppetboard::params {
  validate_bool($enable_catalog)
  validate_bool($enable_query)
  validate_bool($experimental)
  validate_bool($localise_timestamp)
  validate_hash($extra_settings)
  if $puppetdb_ssl_verify {
    unless is_string($puppetdb_ssl_verify) {
      validate_bool($puppetdb_ssl_verify)
    }
  }

  if $manage_group {
    group { $group:
      ensure => present,
    }
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      shell      => '/bin/bash',
      managehome => true,
      gid        => $group,
      system     => true,
      groups     => $groups,
      require    => Group[$group],
    }
  }

  file { $basedir:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  vcsrepo { "${basedir}/puppetboard":
    ensure   => present,
    provider => git,
    owner    => $user,
    source   => $git_source,
    revision => $revision,
    require  => User[$user],
  }

  file { "${basedir}/puppetboard":
    owner   => $user,
    recurse => true,
    require => Vcsrepo["${basedir}/puppetboard"],
  }

  #Template consumes:
  #$dev_listen_host
  #$dev_listen_port
  #$enable_catalog
  #$enable_query
  #$experimental
  #$localise_timestamp
  #$python_loglevel
  #$puppetdb_cert
  #$puppetdb_host
  #$puppetdb_key
  #$puppetdb_port
  #$puppetdb_ssl_verify
  #$puppetdb_timeout
  #$unresponsive
  #$extra_settings
  file {"${basedir}/puppetboard/settings.py":
    ensure  => 'file',
    group   => $group,
    mode    => '0644',
    owner   => $user,
    content => template('puppetboard/settings.py.erb'),
    require => Vcsrepo["${basedir}/puppetboard"],
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
    proxy        => $python_proxy,
  }

  if $listen == 'public' {
    file_line { 'puppetboard listen':
      path    => "${basedir}/puppetboard/dev.py",
      line    => " app.run('0.0.0.0')",
      match   => ' app.run\(\'([\d\.]+)\'\)',
      require => [
        File["${basedir}/puppetboard"],
        Python::Virtualenv["${basedir}/virtenv-puppetboard"]
      ],
    }
  }

  if $manage_git and !defined(Package['git']) {
    package {'git':
      ensure => installed,
    }
  }

  if $manage_virtualenv and !defined(Package[$::puppetboard::params::virtualenv]) {
    class { '::python':
      virtualenv => 'present',
    }
  }

  if $manage_selinux {
    selboolean {'httpd_can_network_relay' :
      persistent => true,
      value      => 'on',
    }
    selboolean {'httpd_can_network_connect' :
      persistent => true,
      value      => 'on',
    }
    selboolean {'httpd_can_network_connect_db' :
      persistent => true,
      value      => 'on',
    }
  }
}
