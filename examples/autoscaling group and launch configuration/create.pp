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


require doatools

node 'default' {
  launch_configuration { 'doatools_role_lc' :
    region          => 'us-east-1',
    image           => 'ami-6d1c2007',
    instance_type   => 't2.micro',
    security_groups => [ 'doatools' ]
  }

  autoscaling_group { 'doatools_role_asg':
    region               => 'us-east-1',
    minimum_instances    => 0,
    maximum_instances    => 5,
    desired_instances    => 2,
    launch_configuration => 'doatools_role_lc',
    subnets              => [ 'doatools_a', 'doatools_b', 'doatools_c' ]
  }
}