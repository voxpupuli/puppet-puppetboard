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
#   (Stdlib::AbsolutePath) WSGI script alias source
#   Default: '/puppetboard'
#
# [*threads*]
#   (Integer) Number of WSGI threads to use.
#   Defaults to 5
#
# [*max_reqs*]
#   (Integer) Limit on number of requests allowed to daemon process
#   Defaults to 0 (no limit)
#
# [*user*]
#   (String) WSGI daemon process user, and daemon process name
#   Defaults to 'puppetboard' ($::puppetboard::params::user)
#
# [*group*]
#   (Integer) WSGI daemon process group owner, and daemon process group
#   Defaults to 'puppetboard' ($::puppetboard::params::group)
#
# [*basedir*]
#   (Stdlib::AbsolutePath) Base directory where to build puppetboard vcsrepo and python virtualenv.
#   Defaults to '/srv/puppetboard' ($::puppetboard::params::basedir)
#
# [*enable_ldap_auth]
#   (Boolean) Whether to enable LDAP auth
#   Defaults to False ($::puppetboard::params::enable_ldap_auth)
#
# [*ldap_bind_dn]
#   (String) LDAP Bind DN
#   No default ($::puppetboard::params::ldap_bind_dn)
#
# [*ldap_bind_password]
#   (String) LDAP password
#   No default ($::puppetboard::params::ldap_bind_password)
#
# [*ldap_url]
#   (String) LDAP connection string
#   No default ($::puppetboard::params::ldap_url)
#
# [*ldap_bind_authoritative]
#   (String) Determines if other authentication providers are used when a user can be mapped to a DN but the server cannot bind with the credentials
#   No default ($::puppetboard::params::ldap_bind_authoritative)
#
# [*ldap_require_group]
#   (Boolean) LDAP group to require on login
#   Default to False ($::puppetboard::params::ldap_require_group)
#
# [*$ldap_require_group_dn]
#   (String) LDAP group DN for LDAP group
#   No default
#
# === Notes:
#
# Make sure you have purge_configs set to false in your apache class!
#
# This runs the WSGI application with a WSGIProcessGroup of $user and
# a WSGIApplicationGroup of %{GLOBAL}.
#
class puppetboard::apache::conf (
  Stdlib::AbsolutePath $wsgi_alias          = '/puppetboard',
  Integer[1] $threads                       = 5,
  Integer[0] $max_reqs                      = 0,
  String[1] $user                           = $puppetboard::params::user,
  String[1] $group                          = $puppetboard::params::group,
  Stdlib::AbsolutePath $basedir             = $puppetboard::params::basedir,
  Boolean $enable_ldap_auth                 = $puppetboard::params::enable_ldap_auth,
  Optional[String] $ldap_bind_dn            = undef,
  Optional[String] $ldap_bind_password      = undef,
  Optional[String] $ldap_url                = undef,
  Optional[String] $ldap_bind_authoritative = undef,
  Boolean $ldap_require_group               = $puppetboard::params::ldap_require_group,
  Optional[String] $ldap_require_group_dn   = undef,
) inherits ::puppetboard::params {

  $docroot = "${basedir}/puppetboard"

  file { "${docroot}/wsgi.py":
    ensure  => present,
    content => template('puppetboard/wsgi.py.erb'),
    owner   => $user,
    group   => $group,
    require => [
      User[$user],
      Vcsrepo[$docroot],
    ],
  }

  file { "${puppetboard::params::apache_confd}/puppetboard.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('puppetboard/apache/conf.erb'),
    require => File["${docroot}/wsgi.py"],
    notify  => Service[$puppetboard::params::apache_service],
  }
}
