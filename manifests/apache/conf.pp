# == Class: puppetboard::apache::conf
#
# Creates an entry in your apache configuration directory
# to run PuppetBoard server-wide (i.e. not in a vhost).
#
# === Parameters
#
# Document parameters here.
#
# [*wsgi_alias*]
#   (string) WSGI script alias source
#   Default: '/puppetboard'
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
# === Notes:
#
# Make sure you have purge_configs set to false in your apache class!
#
# This runs the WSGI application with a WSGIProcessGroup of $user and
# a WSGIApplicationGroup of %{GLOBAL}.
#
class puppetboard::apache::conf (
  $wsgi_alias = '/puppetboard',
  $threads    = 5,
  $user       = $::puppetboard::params::user,
  $group      = $::puppetboard::params::group,
  $basedir    = $::puppetboard::params::basedir,
) inherits ::puppetboard::params {

  $docroot = "${basedir}/puppetboard"

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

  # Template Uses:
  # - $user
  # - $group
  # - $threads
  # - $wsgi_alias
  # - $docroot
  #
  file { "${::puppetboard::params::apache_confd}/puppetboard.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('puppetboard/apache/conf.erb'),
    require => File["${docroot}/wsgi.py"],
    notify  => Service[$::puppetboard::params::apache_service],
  }
}
