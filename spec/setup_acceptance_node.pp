if $facts['os']['name'] == 'Ubuntu' {
  # Needed for facter to fetch facts used by the postgresql module
  if versioncmp($facts['facterversion'], '4.0.0') <= 0 {
    package{ 'lsb-release':
      ensure => present,
    }
  }
}

if $facts['os']['family'] == 'RedHat' {
  if versioncmp($facts['os']['release']['major'], '8') >= 0 {
    package { 'disable-builtin-dnf-postgresql-module':
      ensure   => 'disabled',
      name     => 'postgresql',
      provider => 'dnfmodule',
    }
  }
}
