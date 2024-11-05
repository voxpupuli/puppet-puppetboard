# An example configuration that serve PuppetBoard with Apache and WSGI, using
# LDAP for authentication.

$hostname = 'puppetboard.example.com'

$puppetboard_path = "/srv/www/${hostname}"

include apache::mod::wsgi

class { 'puppetboard':
  version    => '4.2.0',
  basedir    => $puppetboard_path,
  secret_key => stdlib::fqdn_rand_string(64),
}

$wsgi = @(WSGI)
  from __future__ import absolute_import

  import os
  import sys

  me = os.path.dirname(os.path.abspath(__file__))
  os.environ['PUPPETBOARD_SETTINGS'] = os.path.join(me, 'settings.py')

  # Add us to the PYTHONPATH/sys.path if we're not on it
  if not me in sys.path:
      sys.path.insert(0, me)

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
  wsgi_daemon_process    => {
    puppetboard => {
      'python-home'      => $virtualenv_dir,
      user               => $user,
      group              => $group,
      threads            => $threads,
      'maximum-requests' => $max_reqs,
    },
  },
  wsgi_script_aliases    => {
    '/' => "${puppetboard_path}/wsgi.py",
  },
  wsgi_process_group     => 'puppetboard',
  wsgi_application_group => '%{GLOBAL}',
  directories            => [
    {
      path                => '/',
      provider            => 'location',
      auth_basic_provider => 'ldap',
      auth_type           => 'basic',
      auth_name           => 'Login to PuppetBoard',
      auth_ldap_url       => '"ldap://ldap.example.org/ou=people,dc=example,dc=org?uid" STARTTLS',
      auth_ldap_bind_dn   => $bind_dn,
      auth_ldap_bind_pw   => $bind_password.unwrap,
      require             => [
        'ldap-group puppetboard',
      ],
    },
  ],
}

Class['puppetboard'] ~> Class['apache::service']
