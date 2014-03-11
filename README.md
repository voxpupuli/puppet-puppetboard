puppetboard
===========

This is the puppetboard puppet module.

Puppetboard is a puppet dashboard

https://github.com/nedap/puppetboard


Installation
------------

    puppet module install nibalizer-puppetboard


Dependencies
------------

Note that this module no longer explicitly requires the puppetlabs apache module. If you want to use the apache functionality of this module you will have to specify that the apache module is installed with:


    puppet module install puppetlabs-apache

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
class { 'apache::mod::wsgi': }

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

class { 'apache::mod::wsgi': }

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard from example.com/puppetboard
class { 'puppetboard::apache::conf': }
```

### Redhat

RedHat has restrictions on the /etc/apache directory that require wsgi to be configured to use /var/run.

```puppet

  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => "/var/run/wsgi",
  }

```

### Apache, RedHat and a non-standard port


```puppet

# Configure Apache on this server
class { 'apache': }
class { 'apache::mod::wsgi':
  wsgi_socket_prefix => "/var/run/wsgi",
}

# Configure Puppetboard
class { 'puppetboard': }

# Access Puppetboard through pboard.example.com
class { 'puppetboard::apache::vhost':
  vhost_name => 'puppetboard.example.com',
  port => '8888',
}
```



License
-------

Apache 2


Contact
-------

Email: krum.spencer@gmail.com
IRC: #puppetboard and #puppet on freenode

Attribution
-----------

The core of this module was based on Hunter Haugen's puppetboard-vagrant repo.


Support
-------

Please log tickets and issues on github.
