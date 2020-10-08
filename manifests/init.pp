# @summary Base class for Puppetboard. Sets up the user and python environment.
#
# @param user Puppetboard system user.
# @param homedir Puppetboard system user's home directory.
# @param group Puppetboard system group.
# @param groups additional groups for the user that runs puppetboard
# @param basedir Base directory where to build puppetboard vcsrepo and python virtualenv.
# @param git_source Location of upstream Puppetboard GIT repository
# @param puppetdb_host PuppetDB Host
# @param puppetdb_port PuppetDB Port
# @param puppetdb_key path to PuppetMaster/CA signed client SSL key
# @param puppetdb_ssl_verify whether PuppetDB uses SSL or not (true or false), or the path to the puppet CA
# @param puppetdb_cert path to PuppetMaster/CA signed client SSL cert
# @param puppetdb_timeout timeout, in seconds, for connecting to PuppetDB
# @param dev_listen_host host that dev server binds to/listens on
# @param dev_listen_port port that dev server binds to/listens on
# @param unresponsive number of hours after which a node is considered "unresponsive"
# @param enable_catalog Whether to allow the user to browser catalog comparisons.
# @param enable_query Whether to allow the user to run raw queries against PuppetDB.
# @param offline_mode Weather to load static assents (jquery, semantic-ui, tablesorter, etc)
# @param localise_timestamp Whether to localise the timestamps in the UI.
# @param python_loglevel Python logging module log level.
# @param python_proxy HTTP proxy server to use for pip/virtualenv.
# @param python_index HTTP index server to use for pip/virtualenv.
# @param default_environment set the default environment
# @param experimental Enable experimental features.
# @param revision Commit, tag, or branch from Puppetboard's Git repo to be used
# @param manage_git If true, require the git package. If false do nothing.
# @param manage_virtualenv If true, require the virtualenv package. If false do nothing.
# @param python_version Python version to use in virtualenv.
# @param virtualenv_dir Set location where virtualenv will be installed
# @param manage_user If true, manage (create) this group. If false do nothing.
# @param manage_group If true, manage (create) this group. If false do nothing.
# @param manage_selinux If true, manage selinux policies for puppetboard. If false do nothing.
# @param reports_count This is the number of reports that we want the dashboard to display.
# @param listen If set to 'public' puppetboard will listen on all interfaces
# @param extra_settings Defaults to an empty hash '{}'. Used to pass in arbitrary key/value
# @param override Sets the Apache AllowOverride value
# @param enable_ldap_auth Whether to enable LDAP auth
# @param ldap_require_group LDAP group to require on login
# @param apache_confd path to the apache2 vhost directory
# @param apache_service name of the apache2 service
#
# @example
#   configure puppetboard with an apache config for a subpath (http://$fqdn/puppetboard)
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
class puppetboard (
  String $user                                                = 'puppetboard',
  Optional[Stdlib::Absolutepath] $homedir                     = undef,
  String $group                                               = 'puppetboard',
  Optional[Variant[String[1], Array[String[1]]]] $groups      = undef,
  Stdlib::AbsolutePath $basedir                               = '/srv/puppetboard',
  String $git_source                                          = 'https://github.com/voxpupuli/puppetboard',
  String $dev_listen_host                                     = '127.0.0.1',
  Stdlib::Port $dev_listen_port                               = 5000,
  String $puppetdb_host                                       = '127.0.0.1',
  Stdlib::Port $puppetdb_port                                 = 8080,
  Optional[Stdlib::AbsolutePath] $puppetdb_key                = undef,
  Variant[Boolean, Stdlib::AbsolutePath] $puppetdb_ssl_verify = false,
  Optional[Stdlib::AbsolutePath] $puppetdb_cert               = undef,
  Integer[0] $puppetdb_timeout                                = 20,
  Integer[0] $unresponsive                                    = 3,
  Boolean $enable_catalog                                     = false,
  Boolean $enable_query                                       = true,
  Boolean $localise_timestamp                                 = true,
  Puppetboard::Syslogpriority $python_loglevel                = 'info',
  Optional[String[1]] $python_proxy                           = undef,
  Optional[String[1]] $python_index                           = undef,
  Boolean $experimental                                       = false,
  Optional[String] $revision                                  = undef,
  Boolean $manage_selinux                                     = $puppetboard::params::manage_selinux,
  Boolean $manage_user                                        = true,
  Boolean $manage_group                                       = true,
  Boolean $manage_git                                         = false,
  Boolean $manage_virtualenv                                  = false,
  Pattern[/^3\.\d$/] $python_version                          = $puppetboard::params::python_version,
  Stdlib::Absolutepath $virtualenv_dir                        = "${basedir}/virtenv-puppetboard",
  Integer[0] $reports_count                                   = 10,
  String[1] $default_environment                              = 'production',
  Enum['public', 'private'] $listen                           = 'private',
  Boolean $offline_mode                                       = false,
  Hash $extra_settings                                        = {},
  String[1] $override                                         = 'None',
  Boolean $enable_ldap_auth                                   = false,
  Boolean $ldap_require_group                                 = false,
  Stdlib::Absolutepath $apache_confd                          = $puppetboard::params::apache_confd,
  String[1] $apache_service                                   = $puppetboard::params::apache_service,
) inherits puppetboard::params {
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
    require  => [
      User[$user],
      Group[$group],
    ],
  }

  file { "${basedir}/puppetboard":
    owner   => $user,
    recurse => true,
    require => Vcsrepo["${basedir}/puppetboard"],
  }

  file { "${basedir}/puppetboard/settings.py":
    ensure  => 'file',
    group   => $group,
    mode    => '0644',
    owner   => $user,
    content => template('puppetboard/settings.py.erb'),
    require => Vcsrepo["${basedir}/puppetboard"],
  }

  python::pyvenv { $virtualenv_dir:
    ensure     => present,
    version    => $python_version,
    systempkgs => false,
    owner      => $user,
    group      => $group,
    require    => Vcsrepo["${basedir}/puppetboard"],
  }
  python::requirements { "${basedir}/puppetboard/requirements.txt":
    virtualenv => $virtualenv_dir,
    proxy      => $python_proxy,
    owner      => $user,
    group      => $group,
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
    package { 'git':
      ensure => installed,
    }
  }

  if $manage_virtualenv {
    class { 'python':
      virtualenv                => 'present',
      manage_virtualenv_package => true,
      version                   => $python_version,
      dev                       => 'present',
    }
    Class['python'] -> Class['puppetboard']
  }

  if $manage_selinux {
    selboolean { 'httpd_can_network_relay' :
      persistent => true,
      value      => 'on',
    }
    selboolean { 'httpd_can_network_connect' :
      persistent => true,
      value      => 'on',
    }
    selboolean { 'httpd_can_network_connect_db' :
      persistent => true,
      value      => 'on',
    }
  }
}
