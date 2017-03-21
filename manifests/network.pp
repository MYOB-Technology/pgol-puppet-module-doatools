define doatools::network (
  $vpc=$name,
  $l_vpc=$vpc,
  $ensure=lookup('network::ensure', Data, 'first', present),
  $vpc_cidr=lookup('network::vpc_cidr', Data, 'first', '192.168.0.0/24'),
  $region=lookup('network::region', Data, 'first', 'us-east-1'),
  $tags=lookup('network::tags', Data, 'first', {}),
  $availability = lookup('network::availability', Data, 'first', [ 'a', 'b', 'c']),
  $internet_access = lookup('network::internet_access', Data, 'first', true),
  $default_access = lookup('network::default_access', Data, 'first', {
    ingress => [ "all||sg|${name}" ],
    egress  => [ "all||sg|${name}" ],
  }),
  $zones = lookup('network::zones', Data, 'first', undef),
){
  define_network_resources($ensure,
    {  name => $vpc, cidr => $vpc_cidr, region=> $region, tags => $tags, availability => $availability },
    $zones,
    $default_access
  ).each |$r| {
    $rt = $r['resource_type']
    $rts = $r['resources'].keys
    info(" declaring resources: $rt $rts")
    create_resources($r['resource_type'], $r['resources'], {})
  }
}