#
# Make sure you have purge_configs set to false in your apache class!
#
class puppetboard::apache::conf (
  $wsgi_alias = '/puppetboard',
  $threads    = 5,
  $user       = $::puppetboard::params::user,
  $group      = $::puppetboard::params::group,
) inherits ::puppetboard::params {

  $docroot = "/home/${user}/puppetboard"

  file { "${docroot}/wsgi.py":
    ensure  => present,
    content => template('puppetboard/wsgi.py.erb'),
    owner   => $user,
    group   => $group,
    require => User[$user],
  }

  file { "${::puppetboard::params::apache_confd}/puppetboard.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('puppetboard/apache/conf.erb'),
    require => File["${docroot}/wsgi.py"],
    notify  => Service[$::puppetboard::params::apache_service],
  }
}
