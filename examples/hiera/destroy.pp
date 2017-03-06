require doatools

node 'default' {
  doatools::environment {'dev':
    ensure => absent,
  }
}

