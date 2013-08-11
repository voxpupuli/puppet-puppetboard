# == Class: puppetboard
#
# Full description of class puppetboard here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { puppetboard:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class puppetboard(
  $user = 'puppetboard', # The user to run puppetboard as
) {

  class { 'python':
    version    => 'system',
    dev        => true,
    virtualenv => true,
  }

  user { $user:
    ensure     => present,
    home       => "/home/${user}",
    shell      => '/bin/bash',
    managehome => true,
  }

  vcsrepo { "/home/${user}/puppetboard":
    ensure   => present,
    provider => git,
    owner    => $user,
    source   => "https://github.com/nedap/puppetboard",
    require  => User[$user],
  }

  file { "/home/${user}/puppetboard":
    owner   => $user,
    recurse => true,
  }

  python::virtualenv { "/home/${user}/virtenv-puppetboard":
    ensure       => present,
    version      => 'system',
    requirements => "/home/${user}/puppetboard/requirements.txt",
    systempkgs   => true,
    distribute   => false,
    owner        => $user,
    require      => Vcsrepo["/home/${user}/puppetboard"],
  }

}
