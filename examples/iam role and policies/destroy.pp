require doatools

node 'default' {
  iam_role { 'doatools_role':
    ensure => absent,
  }->iam_policy { 'doatools_password':
    ensure => absent,
  }

}
