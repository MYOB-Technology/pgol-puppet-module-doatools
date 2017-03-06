define doatools::network (
  $vpc=$name,
  $l_vpc=$vpc,
  $ensure=lookup('network::ensure', Data, 'first', present),
  $vpc_cidr=lookup('network::vpc_cidr', Data, 'first', '192.168.0.0/24'),
  $region=lookup('network::region', Data, 'first', 'us-east-1'),
  $environment=lookup('network::environment', Data, 'first', $name),
  $availability = lookup('network::availability', Data, 'first', [ 'a', 'b', 'c']),
  $internet_access = lookup('network::internet_access', Data, 'first', true),
  $default_access = lookup('network::default_access', Data, 'first', {
    ingress => [ "all||sg|${name}" ],
    egress  => [ "all||sg|${name}" ],
  }),
  $zones = lookup('network::zones', Data, 'first', undef),
){
  $zones_internal = lest($zones) || {
    [{
      label => '',
      cidr => $vpc_cidr,
      public_ip => true,
    }]
  }




  vpc { $name :
    ensure      => $ensure,
    region      => $region,
    cidr        => $vpc_cidr,
    environment => $environment,
  }

  if $internet_access == "true" or $internet_access == true {
    warning("declaring internet access")
    internet_gateway { $name:
      ensure => $ensure,
      region => $region,
      vpc    => $name,
    }

    if $ensure == absent {
      Internet_gateway[$name] -> Vpc[$name]
    }

  }else {
    warning("declaring NO internet access")
    internet_gateway { $name:
      ensure => absent,
      region => $region,
    }
  }

  # Models the default security group.
  if $ensure == present {
    security_group { $name:
      ensure      => $ensure,
      region      => $region,
      vpc         => $name,
      environment => $environment,
      in          => $default_access['ingress'],
      out         => $default_access['egress'],
    }
  }


  $zones_internal.each |$i, $z | {
    if $z["availability"] != undef {
      $azs = $z["availability"]
    } else {
      $azs = $availability
    }

    $azs.each |$azi, $az | {
      $actual_cidr = make_cidr($z['cidr'], $azi, $azs.size)
      $subnet_name = "${name}_${z['label']}${az}"

      subnet { $subnet_name:
        ensure            => $ensure,
        region            => $region,
        vpc               => $name,
        availability_zone => $az,
        cidr              => $actual_cidr,
        environment       => $environment,
      }

      if $ensure == absent {
        Subnet[$subnet_name] -> Vpc[$name]
      }
    }
  }
}