# An example configuration that serve PuppetBoard with Nginx and Passenger,
# using Puppet certificates for client authentication.

$hostname = 'puppetboard.example.com'

$puppetboard_path = "/srv/www/${hostname}"

class { 'puppetboard':
  version    => '5.4.0',
  basedir    => $puppetboard_path,
  secret_key => stdlib::fqdn_rand_string(64),

  # ...

  notify     => Service['nginx'],
}

$wsgi = @(WSGI)
  from __future__ import absolute_import
  import os
  from puppetboard.app import app as application
  | WSGI

file { "/srv/www/${hostname}/puppetboard/wsgi.py":
  ensure  => file,
  mode    => '0755',
  content => $wsgi,
}

nginx::resource::server { $hostname:
  ssl_verify_client    => 'on',
  ssl_client_cert      => "${settings::ssldir}/certs/ca.pem",
  ssl_crl              => "${settings::ssldir}/crl.pem",
  server_name          => [
    $hostname,
  ],
  use_default_location => false,
  server_cfg_prepend   => {
    passenger_app_root      => "${puppetboard_path}/puppetboard",
    passenger_app_type      => 'wsgi',
    passenger_startup_file  => 'wsgi.py',
    passenger_python        => "${puppetboard_path}/virtenv-puppetboard/bin/python3",
    passenger_user          => 'puppetboard',
    passenger_group         => 'puppetboard',
    passenger_enabled       => 'on',
    passenger_min_instances => 1,
    passenger_env_var       => {
      'PUPPETBOARD_SETTINGS' => "${puppetboard_path}/puppetboard/settings.py",
    },
  },
  www_root             => "${puppetboard_path}/puppetboard/public",
}

nginx::resource::location { "${hostname} /static":
  server   => $hostname,
  location => '/static',
  www_root => "${puppetboard_path}/puppetboard/puppetboard",
}
