define doatools::network (
  $vpc_cidr="192.168.128.0/24",
  $region="us-east-1",
  $environment="demonstration",
  $availability = [ 'a', 'b', 'c'],
  $zones = [
  {
   label => "p",
    cidr => "192.168.128.0/25",
    public_ip => true,
    availability => [ 'a', 'b', 'c' ],
  },
  {
    label => "",
    cidr => "192.168.128.128/25",
    public_ip => false,
    availability => [ 'a', 'c' ],
  }]
)

{
  vpc { "${name}" :
    region => $region,
    cidr => $vpc_cidr,
    environment => "demonstration",    
  }

  $zones.each |$i, $z | {
    if $z["availability"] != undef {
      $azs = $z["availability"] 
    } else {
      $azs = $availability
    }
  
    $azs.each |$azi, $az | {
      $actual_cidr = make_cidr($z["cidr"], $azi, $azs.size)
      subnet { "${name}_${z["label"]}${az}":
        region => $region,
        vpc => $name,
        availability_zone => $az,
        cidr => $actual_cidr,
      }
    }   
  }
}
