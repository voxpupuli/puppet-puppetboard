# @summary Sets up an apache::vhost to run PuppetBoard, and writes an appropriate wsgi.py from template
#
# @param vhost_name The vhost ServerName.
# @param wsgi_alias WSGI script alias source
# @param ip IP for the vhost to bind to
# @param port Port for the vhost to listen on.
# @param ssl If vhost should be configured with ssl
# @param ssl_cert Path to server SSL cert
# @param ssl_key Path to server SSL key
# @param ssl_chain Path to server CA Chain file
# @param threads Number of WSGI threads to use.
# @param user WSGI daemon process user, and daemon process name
# @param group WSGI daemon process group owner, and daemon process group
# @param basedir Base directory where to build puppetboard vcsrepo and python virtualenv.
# @param override Sets the Apache AllowOverride value
# @param enable_ldap_auth Whether to enable LDAP auth
# @param ldap_bind_dn LDAP Bind DN
# @param ldap_bind_password LDAP password
# @param ldap_url LDAP connection string
# @param ldap_bind_authoritative Determines if other authentication providers are used when a user can be mapped to a DN but the server cannot bind with the credentials
# @param ldap_require_group LDAP group to require on login
# @param ldap_require_group_dn LDAP group DN for LDAP group
# @param virtualenv_dir Set location where virtualenv will be installed
# @param custom_apache_parameters A hash passed to the `apache::vhost` for custom settings
class puppetboard::apache::vhost (
  String[1] $vhost_name,
  Stdlib::Unixpath $wsgi_alias                 = '/',
  Optional[Stdlib::IP::Address] $ip            = undef,
  Stdlib::Port $port                           = 5000,
  Boolean $ssl                                 = false,
  Optional[Stdlib::AbsolutePath] $ssl_cert     = undef,
  Optional[Stdlib::AbsolutePath] $ssl_key      = undef,
  Optional[Stdlib::AbsolutePath] $ssl_chain    = undef,
  Integer[1] $threads                          = 5,
  String[1] $user                              = $puppetboard::user,
  String[1] $group                             = $puppetboard::group,
  Stdlib::AbsolutePath $basedir                = $puppetboard::basedir,
  Variant[Array[String[1]], String[1]] $override = $puppetboard::override,
  Boolean $enable_ldap_auth                    = $puppetboard::enable_ldap_auth,
  Optional[String[1]] $ldap_bind_dn            = undef,
  Optional[String[1]] $ldap_bind_password      = undef,
  Optional[String[1]] $ldap_url                = undef,
  Optional[String[1]] $ldap_bind_authoritative = undef,
  Boolean $ldap_require_group                  = $puppetboard::ldap_require_group,
  Optional[String[1]] $ldap_require_group_dn   = undef,
  Stdlib::Absolutepath $virtualenv_dir         = $puppetboard::virtualenv_dir,
  Hash $custom_apache_parameters               = {},
) {
  $wsgi = $facts['os']['family'] ? {
    'Debian' => {
      package_name => 'libapache2-mod-wsgi-py3',
      mod_path     => '/usr/lib/apache2/modules/mod_wsgi.so',
    },
    'RedHat' => $facts['os']['release']['major'] ? {
      '8'     => {
        package_name => $puppetboard::python_version ? {
          '3.6' => 'python3-mod_wsgi',
          '3.8' => 'python38-mod_wsgi',
          '3.9' => 'python39-mod_wsgi',
          default => fail('python version not supported'),
        },
        mod_path     => 'modules/mod_wsgi_python3.so',
      },
      default => {},
    },
    default  => {},
  }
  class { 'apache::mod::wsgi':
    * => $wsgi,
  }

  $docroot = "${basedir}/puppetboard"

  $wsgi_script_aliases = {
    "${wsgi_alias}" => "${docroot}/wsgi.py",
  }

  $wsgi_daemon_process = {
    $user => {
      threads     => $threads,
      group       => $group,
      user        => $user,
      python-home => $virtualenv_dir,
    },
  }

  file { "${docroot}/wsgi.py":
    ensure  => file,
    content => file("${module_name}/wsgi.py"),
    owner   => $user,
    group   => $group,
  }

  if $enable_ldap_auth {
    $ldap_additional_includes = ["${puppetboard::apache_confd}/puppetboard-ldap.part"]
    $ldap_require = File["${puppetboard::apache_confd}/puppetboard-ldap.part"]
    file { 'puppetboard-ldap.part':
      ensure  => file,
      path    => "${puppetboard::apache_confd}/puppetboard-ldap.part",
      owner   => 'root',
      group   => 'root',
      content => epp("${module_name}/apache/ldap.epp",
        {
          'ldap_bind_authoritative' => $ldap_bind_authoritative,
          'ldap_bind_dn'            => $ldap_bind_dn,
          'ldap_bind_password'      => $ldap_bind_password,
          'ldap_require_group_dn'   => $ldap_require_group_dn,
          'ldap_require_group'      => $ldap_require_group,
          'ldap_url'                => $ldap_url,
        },
      ),
      require => File["${docroot}/wsgi.py"],
      notify  => Service[$puppetboard::apache_service],
    }
  }
  else {
    $ldap_additional_includes = undef
    $ldap_require = undef
  }
  apache::vhost { $vhost_name:
    port                => $port,
    ip                  => $ip,
    docroot             => $docroot,
    manage_docroot      => false,
    ssl                 => $ssl,
    ssl_cert            => $ssl_cert,
    ssl_key             => $ssl_key,
    ssl_chain           => $ssl_chain,
    additional_includes => $ldap_additional_includes,
    wsgi_daemon_process => $wsgi_daemon_process,
    wsgi_process_group  => $group,
    wsgi_script_aliases => $wsgi_script_aliases,
    override            => [$override].flatten,
    require             => [File["${docroot}/wsgi.py"], $ldap_require],
    notify              => Service[$puppetboard::apache_service],
    *                   => $custom_apache_parameters,
  }

  File[$puppetboard::settings_file] ~> Service[$puppetboard::apache_service]
}
