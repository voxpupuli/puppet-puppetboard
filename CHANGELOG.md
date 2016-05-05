# Release 2.8.2

* renamed the Repo from puppet-module-puppetboard -> puppet-puppetboard

# Release 2.8.1

* Fix old Versionnumber in metadata.json

# Release 2.8.0

* Official drop Ruby 1.8 support

# Release 2.7.5

* Bumping so that auto-release can fire

# Release 2.7.4

* Fix duplicate reports parameter
* No longer notify non-existent service
* Moved to the voxpupuli space

# Release 2.7.3

* Bumping so that auto-release can fire

# Release 2.7.2

* Moved to the puppet-community space

* Control the number of reports shown.

* puppetdb_ssl renamed to puppetdb_ssl_verify

* Allow puppetboard user's supplementary groups to be set

* Bumped stdlib dependency

* Misc bugs fixed

* Misc Readme improvements


## Contributors

* Author: David Bogen <djb@bogen.org>
* Author: Eric Shamow <eric.shamow@gmail.com>
* Author: Holt Wilkins <hwilkins@palantir.com>
* Author: Igor Galić <i.galic@brainsware.org>
* Author: krion <krionux@gmail.com>
* Author: Patrick Otto <codec@users.noreply.github.com>
* Author: Paul Chechetin <paulche@yandex.ru>
* Author: Robin Bowes <robin.bowes@yo61.com>
* Author: Spencer Krum <nibz@spencerkrum.com>
* Author: stack72 <public@paulstack.co.uk>
* Author: txaj <txaj1@ovh.fr>

# Release 2.6.0

* Changed git managed to installed

* Starting with 2.5.0

* Moved template from managing default_settings.py to settings.py

* Handled better the stringification of ssl_key and ssl_cert

* Added beaker tests

* Abstracted out REPORTS_COUNT

* Misc bug fixes

* Docs improvements

* Lint/syntax testing with travis integration

* Github now reports activity to #puppetboard on freenode

* Allow puppetboard to be prefixed when running in wsgi

* Optionally manage user/group

* Allow timestamps to be localized

## Contributors

* Igor Galić <i.galic@brainsware.org>
* Tomas Theunissen <t.p.theunissen@avisi.nl>
* William Van Hevelingen <blkperl@cat.pdx.edu>
* Colleen Murphy <cmurphy@cat.pdx.edu>
* Wolf Noble <wnoble@rmn.com>
* Thomas Kräuter <kraeutert@gmail.com>
* Sigmund Augdal <sigmund.augdal@uninett.no>
* Daniele Sluijters <github@daenney.net>
