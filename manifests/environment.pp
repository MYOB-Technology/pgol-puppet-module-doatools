#  Copyright (C) 2017 IntechnologyWIFI / Michael Shaw
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

define doatools::environment (
  $ensure = present,
  $region = 'us-east-1',
  $vpc = $name,
  $env = $name,

  $network = lookup('doatools::environment::network', Data, 'first', {
    cidr => '192.168.0.0/24',              #  The CIDR for the VPC
    availability => [ 'a', 'b', 'c'],      #  The availability zones to use
    routes => [ ],                         #  Any non standard routes in format "{cidr}|{target type}|{target-name}"
    dns_hostnames => false,                #  Can be set to true, to enable DNS hostnames
    dns_resolution => true,                #  Can be set to false, to disable DNS resolution
  }),

  $zones = lookup('doatools::environment::zones', Data, 'first', {
    # We can have up to 3 zones defined. Zones define the routing to the outside world.
    # Isolation between servers is handled by security groups and not zones.

    # Public zone subnets have public ip addresses and route traffic via the internet gateway
    'public' => {
      # ipaddr_weighting => 1,
      # format => '%{vpc}%{az}pub',
      # This zone will then use these routes for this nat, instead of the routes in the network routes.
      # routes => [],
      # This grants extra routes to this zones routing table in addition to the network routes.
      # extra_routes => [ ],
    },
    # NAT zone subnets only have private ip addresses, and route traffic via nat gateways.  There will be one nat
    # gateway per IP address provided. nat subnets without their own nat gateway will be routed via another subnet
    # EC2 instances in a nat zone cannot be given a public IP address
    # 'nat' => {
    #  ipaddr_weighting => 1,
    #  format => '%{vpc}%{az}nat',
    #  nat_ipaddr => [ ],
    # This zone will then use these routes for this nat, instead of the routes in the network routes.
    # routes => [],
    # This grants extra routes to this zones routing table in addition to the network routes.
    # extra_routes => [ ],
    #},

    # Private zone subnets do not route traffic to the internet. However, it is possible to add routing to the internet
    # gateway and then attach an elastic IP address to a server to gain access for a temporary fix.
    #'private' => {
    #  ipaddr_weighting => 1,
    #  format => '%{vpc}%{az}pri',
    # This zone will then use these routes for this nat, instead of the routes in the network routes.
    # routes => [],
    # This grants extra routes to this zones routing table in addition to the network routes.
    # extra_routes => [ ],
    #},
  }),

  $server_roles = lookup('doatools::environment::server_roles', Data, 'deep', {

  }),

  $services = lookup('doatools::environment::services', Data, 'deep', {

  }),

  $db_servers = {

  },

  $s3 = {

  },

  $tags = {

  },

  $policies = lookup('doatools::environment::policies', Data, 'deep', {

  })




#  $region=lookup('environment::region', Data, 'first', 'us-east-1'),
#  $network=lookup('environment::network', Data, 'first', { }),
#  $roles=lookup('environment::roles', Data, 'first', {}),
#  $ensure=lookup('environment::ensure', Data, 'first', present)
)  {
  info("declaring environment ${env} in region ${region}.")

  define_environment_resources(
    $name,
    $ensure,
    $region,
    $network,
    $zones,
    $server_roles,
    $services,
    $db_servers,
    $s3,
    $tags,
    $policies,
  ).each |$r| {
    $rt = $r['resource_type']
    $rts = $r['resources'].keys
    info("declaring resources: ${rt} ${rts}")
    debug($r['resources'])
    create_resources($r['resource_type'], $r['resources'], {})
  }
}

