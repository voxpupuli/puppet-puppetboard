# puppetboard

[![License](https://img.shields.io/github/license/voxpupuli/puppet-puppetboard.svg)](https://github.com/voxpupuli/puppet-puppetboard/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/voxpupuli/puppet-puppetboard.svg)](https://travis-ci.org/voxpupuli/puppet-puppetboard)
[![Puppet Forge](http://img.shields.io/puppetforge/v/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge downloads](https://img.shields.io/puppetforge/dt/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)
[![Puppet Forge score](https://img.shields.io/puppetforge/f/puppet/puppetboard.svg)](https://forge.puppetlabs.com/puppet/puppetboard)

#### Table of Contents

- [Overview](#overview)
- [Setup](#setup)
  - [Installation](#installation)
  - [Dependencies](#dependencies)
- [Usage](#usage)
- [Number of Reports](#number-of-reports)
- [Offline Mode](#offline-mode)
- [Set Default Environment](#set-default-environment)
- [Disable SELinux Management](#disable-selinux-management)
- [Apache](#apache)
  - [Apache (with Reverse Proxy)](#apache-with-reverse-proxy)
- [Using SSL to the PuppetDB host](#using-ssl-to-the-puppetdb-host)
  - [Using SSL to PuppetDB \>= 6.9.1](#using-ssl-to-puppetdb--691)
- [Development](#development)
  - [Authors](#authors)

## Overview

Puppet module for installing and managing [Puppetboard](https://github.com/voxpupuli/puppetboard).

Puppetboard is a web interface to [PuppetDB](https://puppet.com/docs/puppetdb/latest/index.html) aiming to replace
the reporting functionality of [Puppet Enterprise console (previously: Puppet Dashboard)](https://puppet.com/docs/pe/latest/console_accessing.html)
for the open source Puppet.

## Setup

### Installation

    puppet module install puppet-puppetboard

### Dependencies

Note that this module no longer explicitly requires the puppetlabs apache module. If you want to use the apache functionality of this module you will have to specify that the apache module is installed with:

    puppet module install puppetlabs-apache

In most cases the module requires the `virtualenv` package. This can be enabled in the module with the `manage_virtualenv` flag set to `true`:

```puppet
class { 'puppetboard':
  manage_virtualenv => true,
  secret_key        => fqdn_rand_string(32),
}
```

If the virtualenv is managed by this module, the [voxpupuli/python](https://forge.puppet.com/puppet/python#puppet-python) will be used. That module uses [voxpupuli/epel](https://forge.puppet.com/puppet/epel#configure-epel-extra-repository-for-enterprise-linux) on RHEL based platforms.

## Usage

Declare the base puppetboard manifest with the below required parameter(s), set to the values you want to use:

```puppet
class { 'puppetboard':
  python_version => '3.9',
  secret_key     => fqdn_rand_string(32),
}
```

This will install the latest stable version of the app from a [PyPI package](https://pypi.org/project/puppetboard/) in a virtualenv created using the requested Python version and keep it up to date.
This example secret key is fine if you have a single-node deployment of the app. If you have a multi-node deployment, you should generate a secret key and use the same one on all nodes.

## Number of Reports

NOTE: In order to have reports present in the dashboard, report storage must be enabled on the Puppet master node.
This is not the default behavior, so it must be enabled.

See https://puppet.com/docs/puppetdb/latest/connect_puppet_server.html#enabling-report-storage for instructions on
report storage.

By default, puppetboard displays only 10 reports. This number can be
controlled to set the number of reports to show.

```puppet
class { 'puppetboard':
  python_version => '3.9',
  secret_key     => fqdn_rand_string(32),
  reports_count  => 40,
}
```

## Offline Mode

If you are running puppetboard in an environment which does not have network access to public CDNs,
puppet board can load static assets (jquery, semantic-ui, tablesorter, etc) from the local web server instead of a CDN:

```puppet
class { 'puppetboard':
  python_version => '3.9',
  secret_key     => fqdn_rand_string(32),
  offline_mode   => true,
}
```

## Set Default Environment

By default, puppetboard defaults to "production" environment. This can be
set to default to a different environment.

```puppet
class { 'puppetboard':
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
  default_environment => 'customers',
}
```

or to default to "All environments":

```puppet
class { 'puppetboard':
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
  default_environment => '*',
}
```

## Disable SELinux Management

```puppet
class { 'puppetboard':
  python_version => '3.9',
  secret_key     => fqdn_rand_string(32),
  manage_selinux => false,
}
```

If manage_selinux is true, manage policies related to SELinux. If false, do nothing. By default, this module will try to determine if SELinux is enabled, and manage the policies if it is.

## Apache

If you want puppetboard accessible through Apache and you're able to use the
official `puppetlabs/apache` Puppet module, this module contains two classes
to help configuration.

The first, `puppetboard::apache::vhost`, will use the `apache::vhost`
defined-type to create a full virtual host. This is useful if you want
puppetboard to be available under an address like http://pboard.example.com:

(The following is generic code used in our tests, it works on Debian 9 and 10, also on Ubuntu 16.04 and 18.04. It will talk to PuppetDB on localhost via http)

```puppet
# Configure Apache on this server
class { 'apache':
  default_vhost => false,
}

# Configure Puppetboard
class { 'puppetboard':
  python_version    => '3.9',
  secret_key        => fqdn_rand_string(32),
  manage_virtualenv => true,
}

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
# Configure Puppetboard
class { 'puppetboard':
  python_version => '3.9',
  secret_key     => fqdn_rand_string(32),
}

# Access Puppetboard from example.com/puppetboard
class { 'puppetboard::apache::conf': }
```

### Apache (with Reverse Proxy)

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
ProxyPass /pboard/ http://dashes.acme:5000/pboard/
ProxyPassReverse /pboard/ http://dashes.acme:5000/pboard/
```

Using the puppetlabs/apache module:

```puppet
apache::vhost { 'example.acme':
  port            => '80',
  docroot         => '/var/www/html',
  redirect_source => [ '/pboard' ],
  redirect_dest   => [ '/pboard/' ],
  proxy_pass      => [
    {
      'path' => '/pboard/',
      'url'  => 'http://dashes.acme:5000/pboard/',
    },
  ],
}
```

## Using SSL to the PuppetDB host

If you would like to use certificate auth into the PuppetDB service you must configure puppetboard to use a client certificate and private key.

You have two options for the source of the client certificate & key:

1. Generate a new certificate, signed by the puppetmaster CA
2. Use the existing puppet client certificate

If you choose option 1, generate the new certificates on the CA puppet master as follows:

```
sudo puppet cert generate puppetboard.example.com
```

Note: this name cannot conflict with an existing certificate name.

The new certificate and private key can be found in $certdir/<NAME>.pem and $privatekeydir/<NAME>.pem on the CA puppet master. If you are not running puppetboard on the CA puppet master you will need to copy the certificate and key to the node running puppetboard.

Here's an example, using new certificates:

```puppet
$ssl_dir = '/var/lib/puppetboard/ssl'
$puppetboard_certname = 'puppetboard.example.com'
class { 'puppetboard':
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
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
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
  manage_virtualenv   => true,
  groups              => 'puppet',
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
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
  manage_virtualenv   => true,
  groups              => 'puppet',
  puppetdb_host       => 'puppetdb.example.com',
  puppetdb_port       => 8081,
  puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
  puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
  puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
}
```

### Using SSL to PuppetDB >= 6.9.1

As of PuppetDB `6.9.1` the `/metrics/v2` API is only accessible on the loopback/localhost
interface of the PuppetDB server. This requires you to run `puppetboard` locally on
that host and configure `puppetdb_host` to `127.0.0.1`:

```puppet

$ssl_dir = $::settings::ssldir
$puppetboard_certname = $::certname
class { 'puppetboard':
  python_version      => '3.9',
  secret_key          => fqdn_rand_string(32),
  manage_virtualenv   => true,
  groups              => 'puppet',
  puppetdb_host       => '127.0.0.1',
  puppetdb_port       => 8081,
  puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
  puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
  puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
}
```

**NOTE** In order for SSL to verify properly in this setup, you'll need your
Puppet SSL certificate to have an IP Subject Alternative Name setup
for `127.0.0.1`, otherwise the certificate verification will fail.
You can set this up in your `puppet.conf` with the `dns_alt_names`
configuration option, documented [here](https://puppet.com/docs/puppet/latest/configuration.html#dnsaltnames).

```ini
[main]
dns_alt_names = puppetdb,puppetdb.domain.tld,puppetboard,puppetboard.domain.tld,IP:127.0.0.1
```

**NOTE** If you need to regenerate your existing cert to add DNS Alt Names
follow the documentation [here](https://puppet.com/docs/puppet/latest/ssl_regenerate_certificates.html#regenerate_agent_certs_and_add_dns_alt_names):

```shell
# remove the existing agent certs
puppetserver ca clean --certname <CERTNAME_OF_YOUR_PUPPETDB>
puppet ssl clean

# stop our services
puppet resource service puppetserver ensure=stopped
puppet resource service puppetdb ensure=stopped

# regenerate our cert
puppetserver ca generate --certname <CERTNAME> --subject-alt-names puppetdb,puppetdb.domain.tld,puppetboard,puppetboard.domain.tld,IP:127.0.0.1 --ca-client
# copy the cert into the PuppetDB directory
cp /etc/puppetlabs/puppet/ssl/certs/<CERTNAME>.pem /etc/puppetlabs/puppetdb/ssl/public.pem
cp /etc/puppetlabs/puppet/ssl/private_keys/<CERTNAME>.pem /etc/puppetlabs/puppetdb/ssl/private.pem

# restart our services
puppet resource service puppetdb ensure=running
puppet resource service puppetserver ensure=running
```

## Development

This module is maintained by [Vox Pupuli](https://voxpupuli.org/). Vox Pupuli
welcomes new contributions to this module, especially those that include
documentation and rspec tests. We are happy to provide guidance if necessary.

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for more details.

Please log tickets and issues on github.

### Authors

- Spencer Krum <krum.spencer@gmail.com>
- Vox Pupuli Team
- The core of this module was based on Hunter Haugen's puppetboard-vagrant repo.
