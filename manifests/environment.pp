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

  $network = {
    cidr => "192.168.0.0/24",              #  The CIDR for the VPC
    availability => [ "a", "b", "c"],      #  The availability zones to use
    routes => [ ],                         #  Any non standard routes in format "{cidr}|{target type}|{target-name}"
    dns_hostnames => false,                #  Can be set to true, to enable DNS hostnames
    dns_resolution => true,                #  Can be set to false, to disable DNS resolution
  },

  $zones = {
    # We can have up to 3 zones defined. Zones define the routing to the outside world.
    # Isolation between servers is handled by security groups and not zones.

    # Public zone subnets have public ip addresses and route traffic via the internet gateway
    "public" => {
      ipaddr_weighting => 2,
      format => "%{vpc}%{az}pub",
      routes => [],                    # This zone will then use these routes for this nat, instead of the routes in
                                       # the network routes.
      extra_routes => [ ],             # This grants extra routes to this zones routing table in addition to the network
                                       # routes.
    },
    # NAT zone subnets only have private ip addresses, and route traffic via nat gateways.  There will be one nat
    # gateway per IP address provided. nat subnets without their own nat gateway will be routed via another subnet
    # EC2 instances in a nat zone cannot be given a public IP address
    "nat" => {
      ipaddr_weighting => 5,
      format => "%{vpc}%{az}nat",
      nat_ipaddr => [ ],
      routes => [],                    # This zone will then use these routes for this nat, instead of the routes in
                                       # the network routes.
      extra_routes => [ ],             # This grants extra routes to this zones routing table in addition to the network
                                       # routes.
    },

    # Private zone subnets do not route traffic to the internet. However, it is possible to add routing to the internet
    # gateway and then attach an elastic IP address to a server to gain access for a temporary fix.
    "private" => {
      ipaddr_weighting => 1,
      format => "%{vpc}%{az}pri",
      routes => [],                    # This zone will then use these routes for this nat, instead of the routes in
                                       # the network routes.
      extra_routes => [ ],             # This grants extra routes to this zones routing table in addition to the network
                                       # routes.
    },
  },

  $server_roles = {
    "role_name_1" => {
      "scaling" => { "min" => 0, "max" => 2, "desired" => 1 },
      "ec2" => {
        "instance_type" => 't2.micro',
        "image" => 'ami...',
      },
      "userdata" => [],
      "services" => [
        "service_1"
      ],
      "zone" => "nat",
    }
  },

  $services = {
    "service_1" => {
      "shared_ports" => [
        "{http,80}=>80",
        "{https,443,cert_arn}=>80",
      ],
      "policies" => [
      ],
      "network" => {
        "in" => [
          # Format is 'source_type|source|protocol|port
          "tcp|80|rss|elb",    # loadbalancer for the role that hosts this service.
          "tcp|80|service|my_other_service",    # all ec2 instances that host the 'my_other_service' service.
          "tcp|22|cidr|0.0.0.0/0",    # A network block
        ],
        "out" => [
          # Format is 'destination_type|destination|protocol|port'
          "tcp|80|cidr|0.0.0.0/0",
          "tcp|443|cidr|0.0.0.0/0",
          "tcp|3306|rds|db_server_name",
        ],
      }
    }
  },

  $db_servers = {
    'server_name' => {
      'zone' => 'private',
      'services' => [
        # Service names that need to access this server.
      ],
      'engine' => 'mysql'

    }

  },

  $s3 = {
    'bucket_name_1' => {
      'policy' => [],
      'grants' => {},
      'cors' => {},
      'contents' => [
      ]
    }
  },

  $tags = {

  },

  $policies = {
    "policy_name1" => {

    }
  }




#  $region=lookup('environment::region', Data, 'first', 'us-east-1'),
#  $network=lookup('environment::network', Data, 'first', { }),
#  $roles=lookup('environment::roles', Data, 'first', {}),
#  $ensure=lookup('environment::ensure', Data, 'first', present)
)  {

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
    $tags
  ).each |$r| {
    $rt = $r['resource_type']
    $rts = $r['resources'].keys
    info("declaring resources: ${rt} ${rts}")
    create_resources($r['resource_type'], $r['resources'], {})
  }
}

