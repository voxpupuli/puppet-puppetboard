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
# [*ssl*]
#   (bool) If vhost should be configured with ssl
#   Defaults to false
#
# [*ssl_cert*]
#   (string, absolute path) Path to server SSL cert
#   No default.
#
# [*ssl_key*]
#   (string, absolute path) Path to server SSL key
#   No default.
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
# [*override*]
#   (string) Sets the Apache AllowOverride value
#   Defaults to 'None' ($::puppetboard::params::apache_override)
#
# [*enable_ldap_auth]
#   (bool) Whether to enable LDAP auth
#   Defaults to False ($::puppetboard::params::enable_ldap_auth)
#
# [*ldap_bind_dn]
#   (string) LDAP Bind DN
#   No default ($::puppetboard::params::ldap_bind_dn)
#
# [*ldap_bind_password]
#   (string) LDAP password
#   No default ($::puppetboard::params::ldap_bind_password)
#
# [*ldap_url]
#   (string) LDAP connection string
#   No default ($::puppetboard::params::ldap_url)
#
# [*ldap_bind_authoritative]
#   (string) Determines if other authentication providers are used 
#            when a user can be mapped to a DN but the server cannot bind with the credentials
#   No default ($::puppetboard::params::ldap_bind_authoritative)
class puppetboard::apache::vhost (
  String $vhost_name,
  String $wsgi_alias                        = '/',
  Integer $port                             = 5000,
  Boolean $ssl                              = false,
  Optional[Stdlib::AbsolutePath] $ssl_cert  = undef,
  Optional[Stdlib::AbsolutePath] $ssl_key   = undef,
  Integer $threads                          = 5,
  String $user                              = $::puppetboard::params::user,
  String $group                             = $::puppetboard::params::group,
  Stdlib::AbsolutePath $basedir             = $::puppetboard::params::basedir,
  String $override                          = $::puppetboard::params::apache_override,
  Boolean $enable_ldap_auth                 = $::puppetboard::params::enable_ldap_auth,
  Optional[String] $ldap_bind_dn            = undef,
  Optional[String] $ldap_bind_password      = undef,
  Optional[String] $ldap_url                = undef,
  Optional[String] $ldap_bind_authoritative = undef,
  Hash $custom_apache_parameters            = {},
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

  if $enable_ldap_auth {
    $ldap_additional_includes = [ "${::puppetboard::params::apache_confd}/puppetboard-ldap.conf" ]
    $ldap_require = File["${::puppetboard::params::apache_confd}/puppetboard-ldap.conf"]
    file { "${::puppetboard::params::apache_confd}/puppetboard-ldap.conf":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('puppetboard/apache/ldap.erb'),
      require => File["${docroot}/wsgi.py"],
      notify  => Service[$::puppetboard::params::apache_service],
    }
  }
  else {
    $ldap_additional_includes = undef
    $ldap_require = undef
  }
  ::apache::vhost { $vhost_name:
    port                        => $port,
    docroot                     => $docroot,
    ssl                         => $ssl,
    ssl_cert                    => $ssl_cert,
    ssl_key                     => $ssl_key,
    additional_includes         => $ldap_additional_includes,
    wsgi_daemon_process         => $user,
    wsgi_process_group          => $group,
    wsgi_script_aliases         => $wsgi_script_aliases,
    wsgi_daemon_process_options => $wsgi_daemon_process_options,
    override                    => $override,
    require                     => [ File["${docroot}/wsgi.py"], $ldap_require ],
    notify                      => Service[$::puppetboard::params::apache_service],
    *                           => $custom_apache_parameters,
  }
  File["${basedir}/puppetboard/settings.py"] ~> Service['httpd']
}
