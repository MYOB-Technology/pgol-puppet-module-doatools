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
  $zone_label= ''
) {
  $subnets= $availability.map |$az| { "${vpc}_${zone_label}${az}" }


  launch_configuration { "${vpc}_${name}_lc" :
    ensure => $ensure,
    region => $region,
    image => $image,
    instance_type => $instance_type,
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
    Autoscaling_group["${vpc}_${name}_asg"]->Launch_configuration["${vpc}_${name}_lc"]
  } else {
    Launch_configuration["${vpc}_${name}_lc"] -> Autoscaling_group["${vpc}_${name}_asg"]
    }

}
