# == Class: puppetboard::apache::vhost
#
# Sets up an apache::vhost to run PuppetBoard,
# and writes an appropriate wsgi.py from template.
#
# === Parameters
#
# Document parameters here.
#
# [*vhost_name*]
#   (string) The vhost ServerName.
#   No default.
#
# [*wsgi_alias*]
#   (string) WSGI script alias source
#   Default: '/'
#
# [*port*]
#   (int) Port for the vhost to listen on.
#   Defaults to 5000.
#
# [*threads*]
#   (int) Number of WSGI threads to use.
#   Defaults to 5
#
# [*user*]
#   (string) WSGI daemon process user, and daemon process name
#   Defaults to 'puppetboard' ($::puppetboard::params::user)
#
# [*group*]
#   (int) WSGI daemon process group owner, and daemon process group
#   Defaults to 'puppetboard' ($::puppetboard::params::group)
#
# [*basedir*]
#   (string) Base directory where to build puppetboard vcsrepo and python virtualenv.
#   Defaults to '/srv/puppetboard' ($::puppetboard::params::basedir)
#
class puppetboard::apache::vhost (
  $vhost_name,
  $wsgi_alias  = '/',
  $port        = 5000,
  $threads     = 5,
  $user        = $::puppetboard::params::user,
  $group       = $::puppetboard::params::group,
  $basedir     = $::puppetboard::params::basedir,
) inherits ::puppetboard::params {

  $docroot = "${basedir}/puppetboard"

  $wsgi_script_aliases = {
    "${wsgi_alias}" => "${docroot}/wsgi.py",
  }

  $wsgi_daemon_process_options = {
    threads => $threads,
    group   => $group,
    user    => $user,
  }

  # Template Uses:
  # - $basedir
  #
  file { "${docroot}/wsgi.py":
    ensure  => present,
    content => template('puppetboard/wsgi.py.erb'),
    owner   => $user,
    group   => $group,
    require => User[$user],
  }

  ::apache::vhost { $vhost_name:
    port                        => $port,
    docroot                     => $docroot,
    wsgi_daemon_process         => $user,
    wsgi_process_group          => $group,
    wsgi_script_aliases         => $wsgi_script_aliases,
    wsgi_daemon_process_options => $wsgi_daemon_process_options,
    require                     => File["${docroot}/wsgi.py"],
    notify                      => Service[$::puppetboard::params::apache_service],
  }

}
