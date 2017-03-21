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
    ensure          => 'absent',
    region          => 'us-east-1',
    vpc_cidr        => '192.168.74.0/23',
    tags            => {
      environment => 'doatools vpc demo',
    },
    availability    => ['a', 'b', 'c'],
    internet_access => true,
    default_access  => {
      ingress => [
        'tcp|80|sg|doatools'
      ],
      egress  => [
        'tcp|3306|sg|doatools'
      ],
    },
    zones           => [ {
        label     =>'%{vpc}%{az}',
        cidr      =>'192.168.74.0/24',
        public_ip => true,
      }, {
        label     =>'%{vpc}%{az}p',
        cidr      => '192.168.75.0/24',
        public_ip => false,
        nat       => ['34.206.108.159', '34.206.183.158', '34.199.175.122' ],
      }
    ]
  }
}

