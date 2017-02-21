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
  vpc { 'doatools':
    region         => 'us-east-1',
    cidr           => '192.168.74.0/23',
    environment    => 'doatools vpc demo',
    dns_hostnames  => true,
    dns_resolution => true,
    is_default     => false,
  }

  subnet { 'doatools_a' :
    region            => 'us-east-1',
    vpc               => 'doatools',
    cidr              => '192.168.74.0/25',
    availability_zone => 'a',
  }

  subnet { 'doatools_b' :
    region            => 'us-east-1',
    vpc               => 'doatools',
    cidr              => '192.168.74.128/25',
    availability_zone => 'b',
  }

  subnet { 'doatools_c' :
    region            => 'us-east-1',
    vpc               => 'doatools',
    cidr              => '192.168.75.0/25',
    availability_zone => 'c',
  }

  security_group { 'doatools2':
    region      => 'us-east-1',
    vpc         => 'doatools',
    description => 'example security group',
    environment => 'doatools vpc demo',
    in          => [
      'tcp|80|sg|doatools2'
    ],
    out         => [
      'tcp|3306|sg|doatools2'
    ],
  }

  internet_gateway { 'doatools':
    region      => 'us-east-1',
    vpc         => 'doatools',
    environment => 'doatools vpc demo',
  }
}