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

define doatools::role (
  $vpc = $name,
  $role = $name,
  $l_vpc=lookup('role::vpc', Data, 'first', $name),
  $l_role=$name,
  $ensure=lookup('role::ensure', Data, 'first', present),
  $region=lookup('role::region', Data, 'first', 'us-east-1'),
  $instance_type=lookup('role::instance_type', Data, 'first', 't2.micro'),
  $image=undef,
  $userdata=lookup('role::userdata', Data, 'first', undef),
  $min=lookup('role::min', Data, 'first', 0),
  $max=lookup('role::max', Data, 'first', 5),
  $desired=lookup('role::desired', Data, 'first', 1),
  $availability = lookup('role::availability', Data, 'deep', [ 'a', 'b', 'c']),
  $zone_labels = lookup('role::zone_labels', Data, 'deep', { 'public' => '%{vpc}%{az}pub', 'private' => '%{vpc}%{az}pri'}),
  $listeners=lookup('role::listeners', Data, 'deep', undef),
  $target=lookup('role::target', Data, 'deep', { }),
  $database=lookup('role::database', Data, 'deep', undef),
  $rds_name=lookup('role::rds_name', Data, 'first', $name),
  $ingress_extra=lookup('role::ingress_extra', Data, 'deep', []),
  $egress_extra=lookup('role::egress_extra', Data, 'deep', []),
) {

  if $image==undef and $ensure==present {
    $l_region=$region
    $image_internal=lookup('role::image', Data, 'first', 'ami-6d1c2007')
  }
  else {
    $image_internal=$image
  }

  # The EC2 security group rules vary depending on whether we have databases and load balancers in the role.
  if $database!=undef {
    $ec2_egress = [
      "tcp|3306|sg|${vpc}_${name}_rds_sg"
    ]
  }
  else {
    $ec2_egress = [
    ]
  }

  if $listeners!=undef {
    $ec2_ingress = [
      "tcp|80|sg|${vpc}_${name}_elb_sg"
    ]
  }
  else {
    $ec2_ingress = [
      'tcp|80|cidr|0.0.0.0/0',
      'tcp|443|cidr|0.0.0.0/0',
    ]
  }


  $public_subnets= $availability.map |$index, $az| { format_zone_label($zone_labels["public"], $l_vpc, $az, $index) }
  $private_subnets = $availability.map |$index, $az| { format_zone_label($zone_labels["private"], $l_vpc, $az, $index) }

  security_group { "${vpc}_${name}_ec2_sg":
    ensure      => $ensure,
    vpc         => $vpc,
    region      => $region,
    description => 'instance security group',
  }

  security_group_rules { "${vpc}_${name}_ec2_sg":
    ensure => $ensure,
    region => $region,
    in     => [$ec2_ingress, $ingress_extra].flatten,
    out    => [$ec2_egress, $egress_extra].flatten,
  }


  if $listeners!=undef {
    $listeners_internal = $listeners.map |$l| {
      if $l == 'http' { "http://${vpc}-${name}-tgt:80" } else {
        "https://${vpc}-${name}-tgt:443?certificate=${l}"
      }
    }

    security_group { "${vpc}_${name}_elb_sg":
      ensure      => $ensure,
      vpc         => $vpc,
      region      => $region,
      description => 'load balancer security group',
    }

    security_group_rules { "${vpc}_${name}_elb_sg":
      ensure => $ensure,
      region => $region,
      in     => [
        'tcp|80|cidr|0.0.0.0/0',
        'tcp|443|cidr|0.0.0.0/0',
      ],
      out    => [
        "tcp|80|sg|${vpc}_${name}_ec2_sg"
      ],
    }

    $target_required = {
      name => "${vpc}-${name}-tgt",
      vpc  => $vpc,
    }

    $target_defaults = {
      check_interval => 30,
      failed         => 3,
      healthy        => 3,
      port           => 80,
      timeout        => 10,
    }

    load_balancer { "${vpc}-${name}-elb":
      ensure          => $ensure,
      region          => $region,
      subnets         => $public_subnets,
      listeners       => $listeners_internal,
      targets         => [deep_merge($target_defaults, $target, $target_required)],
      security_groups => [ "${vpc}_${name}_elb_sg" ]
    }
  } else {

    if $ensure == absent {
      security_group { "${vpc}_${name}_elb_sg":
        ensure => $ensure,
        region => $region,
      }
      load_balancer { "${vpc}-${name}-elb":
        ensure => $ensure,
        region => $region,
      }
    }
  }

  if ($database!=undef) and ($ensure=='present') {

    rds_subnet_group {"${vpc}-${rds_name}-rdsnet":
      ensure  => $ensure,
      region  => $region,
      subnets => $private_subnets
    }

    $l_database_engine = lest($database["engine"]) || { 'mysql'}

    $rds_ingress_ports = [
      ['mysql', [3306]],
      ['mariadb',  [3306]],
      ['oracle-se1', [1525]],
      ['oracle-se2', [1526]],
      ['oracle-se', [1526]],
      ['oracle-ee', [1526]],
      ['sqlserver-ee', [1433]],
      ['sqlserver-se', [1433]],
      ['sqlserver-ex', [1433]],
      ['sqlserver-web', [1433]],
      ['postgres', [5432,5433]],
      ['aurora', [3306]],
    ].reduce([]) | $memo, $engine_port_data | {
      if $engine_port_data[0] == $l_database_engine {
        $engine_port_data[1].map | $p | { "tcp|${p}|sg|${vpc}_${name}_ec2_sg" }
      } else {
        $memo
      }
    }

    $db_data = {
      "${vpc}-${rds_name}-rds" => {
        ensure => $ensure,
        region => $region,
        rds_subnet_group => "${vpc}-${rds_name}-rdsnet",
        security_groups => [ "${vpc}_${name}_rds_sg" ],
        master_username => lest($database["master_username"]) || { 'admin'},
        master_password => lest($database["master_password"]) || { 'password!'},
        database => lest($database["database"]) || { "${vpc}_${name}"},
        multi_az => lest($database["multi_az"]) || { false},
        public_access => lest($database["public_access"]) || { false},
        instance_type => lest($database["instance_type"]) || { 'db.t2.micro'},
        storage_size => lest($database["storage_size"]) || { '50'},
      }
    }

    create_resources(rds, $db_data, $database)

    security_group { "${vpc}_${name}_rds_sg":
      ensure      => $ensure,
      region      => $region,
      vpc         => $vpc,
      description => 'database security group',
    }

    security_group_rules { "${vpc}_${name}_rds_sg":
      ensure => $ensure,
      region => $region,
      in     => $rds_ingress_ports,
      out    => [
      ],
    }

  } else {
    rds_subnet_group {"${vpc}-${rds_name}-rdsnet":
      ensure  => absent,
      region  => $region,
      subnets => $private_subnets
    }

    rds {"${vpc}-${rds_name}-rds":
      ensure           => absent,
      region           => $region,
      rds_subnet_group => "${vpc}-${rds_name}-rdsnet",
    }

    security_group { "${vpc}_${name}_rds_sg":
      ensure => absent,
      region => $region,
    }
  }

  launch_configuration { "${vpc}_${name}_lc" :
    ensure          => $ensure,
    region          => $region,
    image           => $image_internal,
    instance_type   => $instance_type,
    userdata        => $userdata,
    security_groups => [ "${vpc}_${name}_ec2_sg" ]
  }

  autoscaling_group { "${vpc}_${name}_asg":
    ensure               => $ensure,
    region               => $region,
    minimum_instances    => $min,
    maximum_instances    => $max,
    desired_instances    => $desired,
    launch_configuration => "${vpc}_${name}_lc",
    subnets              => $private_subnets,
  }
}
