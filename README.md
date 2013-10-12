puppetboard
===========

NOTE: Right now installing with the module tool is broken. Try the Puppetfile instead.

This is the puppetboard puppet module.

puppetboard is a puppet dashboard

https://github.com/nedap/puppetboard

Usage
-----

Declare the base puppetboard manifest:

```puppet
class { 'puppetboard': }
```

If you want puppetboard available through Apache, there are two classes
to help. The first, `puppetboard::apache::vhost`, will create a full
virtual host. This is useful if you want puppetboard to be available from
http://puppetboard.example.com:

```puppet
# Apache vhost
class { 'puppetboard::apache::vhost':
  vhost_name 'pboard.example.com',
}
```

The second, `puppetboard::apache::conf`, will create a simple entry in
`/etc/apache2/conf.d` (or `/etc/httpd/conf.d`, depending on your distribution).
This is useful if you simply want puppetboard accessible from
http://example.com/puppetboard:

```puppet
# Standard Apache alias
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
