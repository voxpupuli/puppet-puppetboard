puppetboard
===========

This is the puppetboard puppet module.

puppetboard is a puppet dashboard

https://github.com/nedap/puppetboard

Usage
-----

Declare the base puppetboard manifest:

```puppet
class { 'puppetboard': }
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

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard through pboard.example.com
class { 'puppetboard::apache::vhost':
  vhost_name => 'pboard.example.com',
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

package { 'libapache2-mod-wsgi':
  ensure => present,
}

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard from example.com/puppetboard
class { 'puppetboard::apache::conf': }
```

License
-------

Apache 2


Contact
-------

Much of this is taken from Hunter Haugen's puppetboard-vagrant repo

krum.spencer@gmail.com


Support
-------

Please log tickets and issues at github issues.
