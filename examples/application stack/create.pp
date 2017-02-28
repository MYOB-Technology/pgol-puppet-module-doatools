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
  doatools::network { 'doatools':
    region          => 'us-east-1',
    vpc_cidr        => '192.168.74.0/23',
    environment     => 'doatools vpc demo',
    availability    => ['a', 'b', 'c'],
    internet_access => true,
    default_access  => {
      ingress => [
        'tcp|80|sg|doatools'
      ],
      egress  => [
        'tcp|3306|sg|doatools'
      ],
    }
  }->doatools::role { 'doatools':
    region => 'us-east-1',
    image     => 'ami-6d1c2007',
    vpc => 'doatools',
    desired   => 0,
    listeners => [
      'http',
    ],
    target    => {
      port           => 80,
      check_interval => 30,
      timeout        => 10,
      healthy        => 3,
      failed         => 2,
    },
  }
}