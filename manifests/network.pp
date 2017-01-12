define doatools::network (
  $ensure=present,
  $vpc_cidr="192.168.0.0/24",
  $region="us-east-1",
  $environment=$name,
  $availability = [ 'a', 'b', 'c'],
  $zones = [{
    label => "",
    cidr => $vpc_cidr,
    public_ip => true
  }]
){
  vpc { $name :
    ensure => $ensure,
    region => $region,
    cidr => $vpc_cidr,
    environment => $environment,
  }

  $zones.each |$i, $z | {
    if $z["availability"] != undef {
      $azs = $z["availability"] 
    } else {
      $azs = $availability
    }
  
    $azs.each |$azi, $az | {
      $actual_cidr = make_cidr($z["cidr"], $azi, $azs.size)
      $subnet_name = "${name}_${z["label"]}${az}"

      subnet { $subnet_name:
        ensure => $ensure,
        region => $region,
        vpc => $name,
        availability_zone => $az,
        cidr => $actual_cidr,
        environment => $environment,
      }

      if $ensure == absent {
        Subnet[$subnet_name] -> Vpc[$name]
      }
    }   
  }
}
