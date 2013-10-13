class puppetboard::apache::vhost (
  $vhost_name,
  $port        = 5000,
  $threads     = 5,
  $user        = $::puppetboard::params::user,
  $group       = $::puppetboard::params::group,
) inherits ::puppetboard::params {

  $docroot = "/home/${user}/puppetboard",

  $wsgi_script_aliases = {
    '/' => "${docroot}/wsgi.py",
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
    require => User[$user],
  }

  ::apache::vhost { $vhost_name:
    port                        => $port,
    docroot                     => $docroot,
    wsgi_daemon_process         => $user,
    wsgi_process_group          => $group,
    wsgi_script_aliases         => $wsgi_script_aliases,
    wsgi_daemon_process_options => $wsgi_daemon_process_options,
    require                     => File["${docroot}/wsgi.py"],
    notify                      => Service[$::puppetboard::params::apache_service],
  }

}
