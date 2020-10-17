# @summary Creates an entry in your apache configuration directory to run PuppetBoard server-wide (i.e. not in a vhost).
#
# @param wsgi_alias WSGI script alias source
# @param threads Number of WSGI threads to use
# @param max_reqs Limit on number of requests allowed to daemon process Defaults to 0 (no limit)
# @param user WSGI daemon process user, and daemon process name
# @param group WSGI daemon process group owner, and daemon process group
# @param basedir Base directory where to build puppetboard vcsrepo and python virtualenv.
# @param enable_ldap_auth Whether to enable LDAP auth
# @param ldap_bind_dn LDAP Bind DN
# @param ldap_bind_password LDAP password
# @param ldap_url LDAP connection string
# @param ldap_bind_authoritative Determines if other authentication providers are used when a user can be mapped to a DN but the server cannot bind with the credentials
# @param ldap_require_group LDAP group to require on login
# @param ldap_require_group_dn LDAP group DN for LDAP group
# @param virtualenv_dir Set location where virtualenv will be installed
#
# @note Make sure you have purge_configs set to false in your apache class!
# @note This runs the WSGI application with a WSGIProcessGroup of $user and a WSGIApplicationGroup of %{GLOBAL}.
#
class puppetboard::apache::conf (
  Stdlib::Unixpath $wsgi_alias                 = '/puppetboard',
  Integer[1] $threads                          = 5,
  Integer[0] $max_reqs                         = 0,
  String[1] $user                              = $puppetboard::user,
  String[1] $group                             = $puppetboard::group,
  Stdlib::AbsolutePath $basedir                = $puppetboard::basedir,
  Boolean $enable_ldap_auth                    = $puppetboard::enable_ldap_auth,
  Optional[String[1]] $ldap_bind_dn            = undef,
  Optional[String[1]] $ldap_bind_password      = undef,
  Optional[String[1]] $ldap_url                = undef,
  Optional[String[1]] $ldap_bind_authoritative = undef,
  Boolean $ldap_require_group                  = $puppetboard::ldap_require_group,
  Optional[String[1]] $ldap_require_group_dn   = undef,
  Stdlib::Absolutepath $virtualenv_dir         = $puppetboard::virtualenv_dir,
) inherits puppetboard {
  $docroot = "${basedir}/puppetboard"

  file { "${docroot}/wsgi.py":
    ensure  => file,
    content => file("${module_name}/wsgi.py"),
    owner   => $user,
    group   => $group,
    require => [
      User[$user],
      Vcsrepo[$docroot],
    ],
  }

  file { "${puppetboard::params::apache_confd}/puppetboard.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template('puppetboard/apache/conf.erb'),
    require => File["${docroot}/wsgi.py"],
    notify  => Service[$puppetboard::params::apache_service],
  }
}
