if $facts['os']['name'] == 'Ubuntu' {
  # Needed for facter to fetch facts used by the postgresql module
  if versioncmp($facts['facterversion'], '4.0.0') <= 0 {
    package{ 'lsb-release':
      ensure => present,
    }
  }
}
