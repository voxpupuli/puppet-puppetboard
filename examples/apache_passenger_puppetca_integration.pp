# An example configuration that serve PuppetBeard with Apache and Passenger,
# using Puppet certificates for client authentication.

$hostname = 'puppetboard.example.com'

$puppetboard_path = "/srv/www/${hostname}"

class { 'puppetboard':
  version    => '4.2.0',
  basedir    => $puppetboard_path,
  secret_key => stdlib::fqdn_rand_string(64),
}

$wsgi = @(WSGI)
  from __future__ import absolute_import
  import os
  from puppetboard.app import app as application
  | WSGI

file { "${puppetboard_path}/wsgi.py":
  ensure  => file,
  mode    => '0755',
  content => $wsgi,
}

apache::vhost { $hostname:
  port                   => 443,
  docroot                => "${puppetboard_path}/public",
  aliases                => [
    {
      alias => '/static',
      path  => "${puppetboard_path}/puppetboard/static",
    },
  ],
  manage_docroot         => false,
  setenv                 => [
    "PUPPETBOARD_SETTINGS ${puppetboard_path}/settings.py",
  ],
  ssl                    => true,
  ssl_ca                 => "${settings::ssldir}/certs/ca.pem",
  ssl_crl                => "${settings::ssldir}/crl.pem",
  ssl_verify_client      => 'require',
  passenger_app_root     => $puppetboard_path,
  passenger_app_type     => 'wsgi',
  passenger_startup_file => 'wsgi.py',
  passenger_python       => "${puppetboard_path}/virtenv-puppetboard/bin/python3",
  passenger_user         => 'puppetboard',
  passenger_group        => 'puppetboard',
}

Class['puppetboard'] ~> Class['apache::service']
