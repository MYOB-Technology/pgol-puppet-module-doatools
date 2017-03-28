require doatools

node 'default' {
  iam_policy { 'doatools_password':
    ensure => present,
    policy => [{
      'Action'   => 'iam:GetAccountPasswordPolicy',
      'Effect'   => 'Allow',
      'Resource' => '*'
    },
    {
      'Action'   => 'iam:ChangePassword',
      'Effect'   => 'Allow',
      'Resource' => 'arn:aws:iam::309595426446:user/${aws:username}' # lint:ignore:disable_single_quote_string_with_variables
    }],
  }

  iam_role { 'doatools_role':
    ensure   => present,
    policies => [
      'doatools_password'
    ],
  }
}
