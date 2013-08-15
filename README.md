puppetboard
===========

NOTE: Right now installing with the module tool is broken. Try the Puppetfile instead.

This is the puppetboard puppet module.

puppetboard is a puppet dashboard

https://github.com/nedap/puppetboard

Usage
-----

Basically just pick a user and go.


    class { 'puppetboard': }


    class { 'puppetboard': 
      user => 'pboard',
    }


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
