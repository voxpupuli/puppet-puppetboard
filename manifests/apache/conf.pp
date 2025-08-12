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
# @param ldap_require_user if set, list of uids for Require ldap-user directive
# @param ldap_require_dn if set, dn to be matched by Require ldap-dn directive
# @param ldap_require_attribute if set, attributes of LDAP users for Require ldap-attribute directive
# @param ldap_require_filter if set, LDAP search filter for Require ldap-filter directive 
# @param virtualenv_dir Set location where virtualenv will be installed
# @param manage_mod_wsgi A parameter to switch off the use of `apache::mod::wsgi`
# @param custom_mod_wsgi_parameters A hash passed to `apache::mod::wsgi`
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
  Optional[String[1]] $ldap_require_user          = undef,
  Optional[String[1]] $ldap_require_dn            = undef,
  Optional[String[1]] $ldap_require_attribute     = undef,
  Optional[String[1]] $ldap_require_filter        = undef,
  Stdlib::Absolutepath $virtualenv_dir         = $puppetboard::virtualenv_dir,
  Boolean $manage_mod_wsgi                     = true,
  Hash $custom_mod_wsgi_parameters             = {},
) {
  if $manage_mod_wsgi {
    $wsgi = $facts['os']['family'] ? {
      'Debian' => {
        package_name => 'libapache2-mod-wsgi-py3',
        mod_path     => '/usr/lib/apache2/modules/mod_wsgi.so',
      },
      default  => $custom_mod_wsgi_parameters,
    }
    class { 'apache::mod::wsgi':
      * => $wsgi,
    }
  }

  $docroot = "${basedir}/puppetboard"

  file { "${puppetboard::apache_confd}/puppetboard.conf":
    ensure => absent,
  }
  -> file { "${docroot}/wsgi.py":
    ensure  => file,
    content => file("${module_name}/wsgi.py"),
    owner   => $user,
    group   => $group,
  }
  -> apache::custom_config { 'puppetboard':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => epp("${module_name}/apache/conf.epp",
      {
        'docroot'                 => $docroot,
        'enable_ldap_auth'        => $enable_ldap_auth,
        'group'                   => $group,
        'ldap_bind_authoritative' => $ldap_bind_authoritative,
        'ldap_bind_dn'            => $ldap_bind_dn,
        'ldap_bind_password'      => $ldap_bind_password,
        'ldap_require_group_dn'   => $ldap_require_group_dn,
        'ldap_require_group'      => $ldap_require_group,
        'ldap_require_user'       => $ldap_require_user,
        'ldap_require_dn'         => $ldap_require_dn,
        'ldap_require_attribute'  => $ldap_require_attribute,
        'ldap_require_filter'     => $ldap_require_filter,
        'ldap_url'                => $ldap_url,
        'max_reqs'                => $max_reqs,
        'threads'                 => $threads,
        'user'                    => $user,
        'virtualenv_dir'          => $virtualenv_dir,
        'wsgi_alias'              => $wsgi_alias,
      },
    ),
  }
}
