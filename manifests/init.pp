# @summary Base class for Puppetboard. Sets up the user and python environment.
#
# @param install_from Specify how the app should be installed
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
# @param unresponsive number of hours after which a node is considered "unresponsive"
# @param enable_catalog Whether to allow the user to browser catalog comparisons.
# @param enable_query Whether to allow the user to run raw queries against PuppetDB.
# @param offline_mode Weather to load static assents (jquery, semantic-ui, tablesorter, etc)
# @param localise_timestamp Whether to localise the timestamps in the UI.
# @param python_loglevel Python logging module log level.
# @param python_proxy HTTP proxy server to use for pip/virtualenv.
# @param python_index HTTP index server to use for pip/virtualenv.
# @param python_systempkgs Python system packages available in virtualenv.
# @param default_environment set the default environment
# @param revision Commit, tag, or branch from Puppetboard's Git repo to be used
# @param version PyPI package version to be installed
# @param use_pre_releases if version is set to 'latest', then should pre-releases be used too?
# @param manage_git If true, require the git package. If false do nothing.
# @param manage_virtualenv If true, require the virtualenv package. If false do nothing.
# @param python_version Python version to use in virtualenv.
# @param virtualenv_dir Set location where virtualenv will be installed
# @param manage_user If true, manage (create) this group. If false do nothing.
# @param manage_group If true, manage (create) this group. If false do nothing.
# @param package_name Name of the package to install puppetboard
# @param manage_selinux If true, manage selinux policies for puppetboard. If false do nothing.
# @param reports_count This is the number of reports that we want the dashboard to display.
# @param settings_file Path to puppetboard configuration file
# @param extra_settings Defaults to an empty hash '{}'. Used to pass in arbitrary key/value
# @param override Sets the Apache AllowOverride value
# @param enable_ldap_auth Whether to enable LDAP auth
# @param ldap_require_group LDAP group to require on login
# @param apache_confd path to the apache2 vhost directory
# @param apache_service name of the apache2 service
# @param secret_key used for CSRF prevention and more. It should be a long, secret string, the same for all instances of the app. Required since Puppetboard 5.0.0.
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
  Stdlib::Absolutepath $apache_confd,
  String[1] $apache_service,
  Python::Version $python_version,
  Enum['package', 'pip', 'vcsrepo'] $install_from             = 'pip',
  Boolean $manage_selinux                                     = pick($facts['os.selinux.enabled'], false),
  String $user                                                = 'puppetboard',
  Optional[Stdlib::Absolutepath] $homedir                     = undef,
  String $group                                               = 'puppetboard',
  Optional[Variant[String[1], Array[String[1]]]] $groups      = undef,
  Stdlib::AbsolutePath $basedir                               = '/srv/puppetboard',
  String $git_source                                          = 'https://github.com/voxpupuli/puppetboard',
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
  Boolean $python_systempkgs                                  = false,
  Optional[String] $revision                                  = undef,
  Boolean $manage_user                                        = true,
  Boolean $manage_group                                       = true,
  Optional[String[1]] $package_name                           = undef,
  Boolean $manage_git                                         = false,
  Boolean $manage_virtualenv                                  = false,
  Stdlib::Absolutepath $virtualenv_dir                        = "${basedir}/virtenv-puppetboard",
  Integer[0] $reports_count                                   = 10,
  String[1] $default_environment                              = 'production',
  Boolean $offline_mode                                       = false,
  Stdlib::Absolutepath $settings_file                         = "${basedir}/puppetboard/settings.py",
  Hash $extra_settings                                        = {},
  Variant[Array[String[1]], String[1]] $override              = ['None'],
  Boolean $enable_ldap_auth                                   = false,
  Boolean $ldap_require_group                                 = false,
  Variant[Enum['latest'], String[1]] $version                 = 'latest',
  Boolean $use_pre_releases                                   = false,
  Optional[String[1]] $secret_key                             = undef,
) {
  if !$secret_key {
    $message = join([
        "Starting with Puppetboard 5.0.0 providing own \$secret_key is required.",

        'See https://github.com/voxpupuli/puppetboard/issues/721 for more info.',

        'If you run Puppetboard on a single node with static FQDN then you can set it the following code',
        "to generate a random but not changing value: \${fqdn_rand_string(32)}",
    ], ' ')

    if $version == 'latest' or versioncmp($version, '5.0.0') >= 0 {
      fail($message)
    } else {
      notify { 'Warning':
        message => $message,
      }
    }
  }

  if $manage_group {
    group { $group:
      ensure => present,
      system => true,
    }
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      shell      => '/bin/sh',
      home       => $homedir,
      managehome => true,
      gid        => $group,
      system     => true,
      groups     => $groups,
      require    => Group[$group],
    }
  }

  $pyvenv_proxy_env = $python_proxy ? {
    undef   => [],
    default => [
      "HTTP_PROXY=${python_proxy}",
      "HTTPS_PROXY=${python_proxy}",
    ]
  }

  if $install_from in ['pip', 'vcsrepo'] {
    file { $basedir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
      mode   => '0755',
    }
  }

  case $install_from {
    'package': {
      package { $package_name:
        ensure => installed,
      }
    }
    'pip': {
      if $revision {
        fail("'pip' installation method uses \$version parameter to specify version, not \$revision.")
      }

      file { "${basedir}/puppetboard":
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true, # such cleanup is needed in case of a switch from install_from=vcsrepo to install_from=pip
      }

      python::pyvenv { $virtualenv_dir:
        ensure      => present,
        version     => $python_version,
        systempkgs  => $python_systempkgs,
        owner       => $user,
        group       => $group,
        require     => File[$basedir],
        environment => $pyvenv_proxy_env,
      }

      $install_args = $use_pre_releases ? {
        true    => '--pre',
        default => undef,
      }

      python::pip { 'puppetboard':
        ensure       => $version,
        virtualenv   => $virtualenv_dir,
        proxy        => $python_proxy,
        owner        => $user,
        group        => $group,
        require      => Python::Pyvenv[$virtualenv_dir],
        install_args => $install_args,
      }
    }
    'vcsrepo': {
      if $version != 'latest' {
        fail("'vcsrepo' installation method uses \$revision parameter to specify version, not \$version.")
      }

      notify { 'Not recommended':
        message => "This installation method is recommended mainly for the contributors to voxpupuli/puppetboard.
                    Consider switching to 'pip' if you are not one of them.",
      }

      vcsrepo { "${basedir}/puppetboard":
        ensure   => present,
        provider => git,
        user     => $user,
        source   => $git_source,
        revision => $revision,
        require  => [
          User[$user],
          Group[$group],
        ],
        before   => [
          File[$settings_file],
        ],
        notify   => Python::Requirements["${basedir}/puppetboard/requirements.txt"],
      }

      python::pyvenv { $virtualenv_dir:
        ensure      => present,
        version     => $python_version,
        systempkgs  => false,
        owner       => $user,
        group       => $group,
        require     => Vcsrepo["${basedir}/puppetboard"],
        environment => $pyvenv_proxy_env,
      }

      python::requirements { "${basedir}/puppetboard/requirements.txt":
        virtualenv => $virtualenv_dir,
        proxy      => $python_proxy,
        owner      => $user,
        group      => $group,
      }
    }
    default: {
      fail("Unsupported installation method: ${install_from}")
    }
  }

  file { $settings_file:
    ensure  => 'file',
    group   => $group,
    mode    => '0644',
    owner   => $user,
    content => template('puppetboard/settings.py.erb'),
  }

  if $manage_git and !defined(Package['git']) {
    package { 'git':
      ensure => installed,
    }
  }

  if $manage_virtualenv {
    class { 'python':
      version => $python_version,
      dev     => 'present',
      venv    => 'present',
    }
    Class['python'] -> Class['puppetboard']
  }

  if $manage_selinux {
    # Include puppet/selinux
    include selinux
    # Set SELinux booleans required for httpd proper functioning
    # https://linux.die.net/man/8/httpd_selinux
    selinux::boolean {
      default:
        ensure     => 'on',
        persistent => true,
        ;
      # allow httpd scripts to connect to network: Puppetboard connects
      # to PuppetDB
      'httpd_can_network_connect':
        ;
      # allow httpd script to connect to database servers: PuppetDB relies
      # on PostgreSQL
      'httpd_can_network_connect_db':
        ;
      # allow httpd to be used as a forward/reverse proxy
      'httpd_can_network_relay':
        ;
      # enable cgi support
      'httpd_enable_cgi':
        ;
    }
    # Set context for wsgi and settings
    selinux::fcontext {
      default:
        ensure => present,
        notify => Selinux::Exec_restorecon["${basedir}/puppetboard"],
        ;
      "${basedir}/puppetboard/wsgi.py":
        seltype  => 'httpd_sys_script_exec_t',
        ;
      $settings_file :
        require => File[$settings_file],
        seltype => 'httpd_sys_content_t',
        ;
    }
    # Apply changes above
    selinux::exec_restorecon { "${basedir}/puppetboard":
      notify => Service['httpd'],
    }

    if $manage_virtualenv {
      # Set context for venv files
      selinux::fcontext {
        default:
          ensure  => present,
          require => Python::Pip['puppetboard'],
          notify  => Selinux::Exec_restorecon[$virtualenv_dir],
          ;
        "${virtualenv_dir} static files":
          seltype  => 'httpd_sys_content_t',
          pathspec => "${virtualenv_dir}(/.*\\.(cfg|css|html|ico|js|pem|png|svg|ttf|txt|woff|woff2|xml))?",
          ;
        "${virtualenv_dir} METADATA":
          seltype  => 'httpd_sys_content_t',
          pathspec => "${virtualenv_dir}(/.*/METADATA)?",
          ;
        "${virtualenv_dir} executables":
          seltype  => 'httpd_sys_script_exec_t',
          pathspec => "${virtualenv_dir}(/.*\\.(pth|py|pyc|pyi|so))?",
          ;
      }
      # Apply changes above
      selinux::exec_restorecon { $virtualenv_dir :
        notify => Service['httpd'],
      }
    }
  }
}
