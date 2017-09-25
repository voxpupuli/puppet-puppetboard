# puppetboard

[![License](https://img.shields.io/github/license/voxpupuli/puppet-puppetboard.svg)](https://github.com/voxpupuli/puppet-puppetboard/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/voxpupuli/puppet-puppetboard.svg)](https://travis-ci.org/voxpupuli/puppet-puppetboard)
[![Puppet Forge](http://img.shields.io/puppetforge/v/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge downloads](https://img.shields.io/puppetforge/dt/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge score](https://img.shields.io/puppetforge/f/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)

#### Table of Contents

1. [Overview](#overview)
1. [Setup](#setup)
    * [Installation](#installation)
    * [Dependencies](#dependencies)
1. [Usage](#usage)
1. [Number of Reports](#number-of-reports)
1. [Offline Mode](#offline-mode)
1. [Set Default Environment](#set-default-environment)
1. [Disable SELinux](#disable-selinux)
    * [Apache](#apache)
      - [Apache (with Reverse Proxy)](#apache-with-reverse-proxy)
    * [Redhat/CentOS](#redhatcentos)
    * [Apache, RedHat/CentOS and a non-standard port](#apache-redhatcentos-and-a-non-standard-port)
    * [Using SSL to the PuppetDB host](#using-ssl-to-the-puppetdb-host)
1. [Development](#development)
    * [Authors](#authors)

## Overview

This is the puppetboard puppet module.

Puppetboard is an open source puppet dashboard

https://github.com/voxpupuli/puppetboard


## Setup

### Installation

    puppet module install puppet-puppetboard

### Dependencies
Note Oracle linux 5 on puppet versions 4.6.0 to 4.7.1 has pip package problem
which will cause an error trying to install puppetboard.

Note that this module no longer explicitly requires the puppetlabs apache module. If you want to use the apache functionality of this module you will have to specify that the apache module is installed with:

    puppet module install puppetlabs-apache

On RedHat type systems, EPEL may also need to be configured; you can use the
[stahnma/epel](https://forge.puppet.com/stahnma/epel) module if you don't
already have it configured.

This module also requires the ``git`` and ``virtualenv`` packages. These can be enabled in the module by:


```puppet
class { 'puppetboard':
  manage_git        => true,
  manage_virtualenv => true,
}

```

or by:

```puppet
class { 'puppetboard':
  manage_git        => 'latest',
  manage_virtualenv => 'latest',
}

```

## Usage

Declare the base puppetboard manifest:

```puppet
class { 'puppetboard': }
```

Number of Reports
-----

NOTE: In order to have reports present in the dashboard, report storage must be enabled on the Puppet master node.
This is not the default behavior, so it mush be enabled.

See https://docs.puppet.com/puppetdb/latest/connect_puppet_master.html#enabling-report-storage for instructions on
report storage.

By default, puppetboard displays only 10 reports. This number can be
controlled to set the number of repports to show.

```puppet
class { 'puppetboard':
  reports_count => 40
}

```
Offline Mode
-----

If you are running puppetboard in an environment which does not have network access to public CDNs,
puppet board can load static assets (jquery, semantic-ui, tablesorter, etc) from the local web server instead of a CDN:

```puppet
class { 'puppetboard':
  offline_mode => true,
}
```

Set Default Environment
-----

by default, puppetboard defaults to "production" environment. This can be
set to default to a different environment.

```puppet
class { 'puppetboard':
  default_environment => 'customers',
}
```

or to default to "All environments":

```puppet
class { 'puppetboard':
  default_environment => '*',
}
```


Disable SELinux
-----
```puppet
class { 'puppetboard':
  manage_selinux => false,
}
```

### Apache

If you want puppetboard accessible through Apache and you're able to use the
official `puppetlabs/apache` Puppet module, this module contains two classes
to help configuration.

The first, `puppetboard::apache::vhost`, will use the `apache::vhost`
defined-type to create a full virtual host. This is useful if you want
puppetboard to be available from http://pboard.example.com:

```puppet

# Configure Apache on this server
class { 'apache': }
class { 'apache::mod::wsgi': }

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard through pboard.example.com
class { 'puppetboard::apache::vhost':
  vhost_name => 'pboard.example.com',
  port       => 80,
}
```

The second, `puppetboard::apache::conf`, will create an entry in
`/etc/apache2/conf.d` (or `/etc/httpd/conf.d`, depending on your distribution).
This is useful if you simply want puppetboard accessible from
http://example.com/puppetboard:

```puppet
# Configure Apache
# Ensure it does *not* purge configuration files
class { 'apache':
  purge_configs => false,
  mpm_module    => 'prefork',
  default_vhost => true,
  default_mods  => false,
}

class { 'apache::mod::wsgi': }

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard from example.com/puppetboard
class { 'puppetboard::apache::conf': }
```

#### Apache (with Reverse Proxy)

You can also relocate puppetboard to a sub-URI of a Virtual Host. This is
useful if you want to reverse-proxy puppetboard, but are not planning on
dedicating a domain just for puppetboard:

```puppet
class { 'puppetboard::apache::vhost':
  vhost_name => 'dashes.acme',
  wsgi_alias => '/pboard',
}
```

In this case puppetboard will be available (on the default) on
http://dashes.acme:5000/pboard. You can then reverse-proxy to it like so:

```apache
Redirect /pboard /pboard/
ReverseProxy /pboard/ http://dashes.acme:5000/pboard/
ProxyPassReverse /pboard/ http://dashes.acme:5000/pboard/
```

### Redhat/CentOS

RedHat/CentOS has restrictions on the /etc/apache directory that require wsgi to be configured to use /var/run.

```puppet

  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => "/var/run/wsgi",
  }

```

### Apache, RedHat/CentOS and a non-standard port


```puppet

# Configure Apache on this server
class { 'apache': }
class { 'apache::mod::wsgi':
  wsgi_socket_prefix => "/var/run/wsgi",
}

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard through pboard.example.com, port 8888
class { 'puppetboard::apache::vhost':
  vhost_name => 'puppetboard.example.com',
  port => '8888',
}
```

### Using SSL to the PuppetDB host


If you would like to use certificate auth into the PuppetDB service you must configure puppetboard to use a client certificate and private key.

You have two options for the source of the client certificate & key:

1. Generate a new certificate, signed by the puppetmaster CA
2. Use the existing puppet client certificate

If you choose option 1, generate the new certificates on the CA puppet master as follows:
```
sudo puppet cert generate puppetboard.example.com
```
Note: this name cannot conflict with an existing certificate name.

The new certificate and private key can be found in $certdir/<NAME>.pem and $privatekeydir/<NAME>.pem on the CA puppet master. If you are not running puppetboard on the CA puppet master you will need to copy the certificate and key to the node runing puppetboard.

Here's an example, using new certificates:
```puppet
$ssl_dir = '/var/lib/puppetboard/ssl'
$puppetboard_certname = 'puppetboard.example.com'
class { 'puppetboard':
  manage_virtualenv   => true,
  puppetdb_host       => 'puppetdb.example.com',
  puppetdb_port       => 8081,
  puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
  puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
  puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
}
```
If you are re-using the existing puppet client certificates, they will already exist on the node (assuming puppet has been run and the client cert signed by the puppet master). However, the puppetboaard user will not have permission to read the private key unless you add it to the puppet group.

Here's a complete example, re-using the puppet client certs:

```puppet
$ssl_dir = $::settings::ssldir
$puppetboard_certname = $::certname
class { 'puppetboard':
  groups              => 'puppet',
  manage_virtualenv   => true,
  puppetdb_host       => 'puppetdb.example.com',
  puppetdb_port       => 8081,
  puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
  puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
  puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
}
```
Note that both the above approaches only work if you have the Puppet CA root certificate added to the root certificate authority file used by your operating system. If you want to specify the location to the Puppet CA file ( you probably do) you have to use the syntax below. Currently this is a bit of a gross hack, but it's an open issue to resolve it in the Puppet module:

```puppet
$ssl_dir = $::settings::ssldir
$puppetboard_certname = $::certname
class { 'puppetboard':
  groups              => 'puppet',
  manage_virtualenv   => true,
  puppetdb_host       => 'puppetdb.example.com',
  puppetdb_port       => 8081,
  puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
  puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
  puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
}
```

## Development

This module is maintained by [Vox Pupuli](https://voxpupuli.org/). Voxpupuli
welcomes new contributions to this module, especially those that include
documentation and rspec tests. We are happy to provide guidance if necessary.

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for more details.

Please log tickets and issues on github.

### Authors
* Spencer Krum <krum.spencer@gmail.com>
* Voxpupuli Team
* The core of this module was based on Hunter Haugen's puppetboard-vagrant repo.
