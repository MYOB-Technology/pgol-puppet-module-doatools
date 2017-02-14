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
  $ensure=present,
  $region="us-east-1",
  $vpc=$name,
  $instance_type='t2.micro',
  $image=default,
  $min=0,
  $max=5,
  $desired=1,
  $availability = [ 'a', 'b', 'c'],
  $zone_label= '',
  $listeners=undef,
  $target={

  },
) {
  $subnets= $availability.map |$az| { "${vpc}_${zone_label}${az}" }

  security_group { "${vpc}_${name}_ec2_sg":
    ensure => $ensure,
    vpc => $vpc,
    region => $region,
    description => "instance security group",
  }

  if $listeners!=undef {
    $listeners_internal = $listeners.map |$l| {
      if $l == "http" { "http://${vpc}-${name}-tgt:80" } else {
        "https://${vpc}-${name}-tgt:443?certificate=${l}"
      }
    }

    security_group { "${vpc}_${name}_elb_sg":
      ensure => $ensure,
      vpc => $vpc,
      region => $region,
      description => "load balancer security group",
    }

    $target_internal = {
      name => "${vpc}-${name}-tgt",
      port => $target['port'],
      check_interval => $target['check_interval'],
      timeout => $target['timeout'],
      healthy => $target['healthy'],
      failed => $target['failed'],
      vpc => $vpc
    }

    load_balancer { "${vpc}-${name}-elb":
      ensure => $ensure,
      region => $region,
      subnets => $subnets,
      listeners => $listeners_internal,
      targets => [$target_internal],
      security_groups => [ "${vpc}_${name}_elb_sg" ]
    }
  } else {
    if $ensure == absent {
      security_group { "${vpc}_${name}_elb_sg":
        region => $region,
        ensure => $ensure
      }
      load_balancer { "${vpc}-${name}-elb":
        region => $region,
        ensure => $ensure,
      }

      Load_balancer["${vpc}-${name}-elb"] -> Security_group["${vpc}_${name}_elb_sg"] -> Vpc[$vpc]
    }
  }





  launch_configuration { "${vpc}_${name}_lc" :
    ensure => $ensure,
    region => $region,
    image => $image,
    instance_type => $instance_type,
    security_groups => [ "${vpc}_${name}_ec2_sg" ]
  }

  autoscaling_group { "${vpc}_${name}_asg":
    ensure => $ensure,
    region => $region,
    minimum_instances => $min,
    maximum_instances => $max,
    desired_instances => $desired,
    launch_configuration => "${vpc}_${name}_lc",
    subnets => $subnets,
  }


  if $ensure == absent {
    Autoscaling_group["${vpc}_${name}_asg"]->Launch_configuration["${vpc}_${name}_lc"]->Security_group["${vpc}_${name}_ec2_sg"]->Doatools::Network[$vpc]
    Security_group["${vpc}_${name}_ec2_sg"]->Vpc[$vpc]
  } else {
    Security_group["${vpc}_${name}_ec2_sg"]->Launch_configuration["${vpc}_${name}_lc"] -> Autoscaling_group["${vpc}_${name}_asg"]
  }

}
