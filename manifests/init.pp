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
# [*homedir*]
#   (string) Puppetboard system user's home directory.
#   Defaults to undef, which will make the default home directory /home/$user
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
#   (string, absolute path) Base directory where to build puppetboard vcsrepo and python virtualenv.
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
# [*offline_mode*]
#   (bool) Weather to load static assents (jquery, semantic-ui, tablesorter, etc)
#   Defaults to 'False' ($::puppetboard::params::offline_mode
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
# [*python_index*]
#   (string) HTTP index server to use for pip/virtualenv.
#   Defaults to false ($::puppetboard::params::python_index)
#
# [*python_use_epel*]
#   (bool) Whether the Python class will use attempt to manage EPEL or not.
#   Defaults to undef.
#
# [*default_environment*]
#   (string) set the default environment
#   Defaults to production ($::puppetboard::params::default_environment
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
  String $user                                                = $::puppetboard::params::user,
  Optional[String] $homedir                                   = undef,
  String $group                                               = $::puppetboard::params::group,
  Optional[Variant[String, Array[String]]] $groups            = undef,
  Stdlib::AbsolutePath $basedir                               = $::puppetboard::params::basedir,
  String $git_source                                          = $::puppetboard::params::git_source,
  String $dev_listen_host                                     = $::puppetboard::params::dev_listen_host,
  Integer $dev_listen_port                                    = $::puppetboard::params::dev_listen_port,
  String $puppetdb_host                                       = $::puppetboard::params::puppetdb_host,
  Integer $puppetdb_port                                      = $::puppetboard::params::puppetdb_port,
  Optional[Stdlib::AbsolutePath] $puppetdb_key                = undef,
  Variant[Boolean, Stdlib::AbsolutePath] $puppetdb_ssl_verify = $::puppetboard::params::puppetdb_ssl_verify,
  Optional[Stdlib::AbsolutePath] $puppetdb_cert               = undef,
  Integer $puppetdb_timeout                                   = $::puppetboard::params::puppetdb_timeout,
  Integer $unresponsive                                       = $::puppetboard::params::unresponsive,
  Boolean $enable_catalog                                     = $::puppetboard::params::enable_catalog,
  Boolean $enable_query                                       = $::puppetboard::params::enable_query,
  Boolean $localise_timestamp                                 = $::puppetboard::params::localise_timestamp,
  Puppetboard::Syslogpriority $python_loglevel                = $::puppetboard::params::python_loglevel,
  Optional[String] $python_proxy                              = undef,
  Optional[String] $python_index                              = undef,
  Optional[Boolean] $python_use_epel                          = undef,
  Boolean $experimental                                       = $::puppetboard::params::experimental,
  Optional[String] $revision                                  = undef,
  Boolean $manage_selinux                                     = $::puppetboard::params::manage_selinux,
  Boolean $manage_user                                        = true,
  Boolean $manage_group                                       = true,
  Boolean $manage_git                                         = false,
  Boolean $manage_virtualenv                                  = false,
  Integer $reports_count                                      = $::puppetboard::params::reports_count,
  String $default_environment                                 = $::puppetboard::params::default_environment,
  String $listen                                              = $::puppetboard::params::listen,
  Boolean $offline_mode                                       = $::puppetboard::params::offline_mode,
  Hash $extra_settings                                        = $::puppetboard::params::extra_settings,
) inherits ::puppetboard::params {

  if $manage_group {
    group { $group:
      ensure => present,
      system => true,
    }
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      shell      => '/bin/bash',
      home       => $homedir,
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
    index        => $python_index,
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
      dev        => 'present',
      use_epel   => $python_use_epel,
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
