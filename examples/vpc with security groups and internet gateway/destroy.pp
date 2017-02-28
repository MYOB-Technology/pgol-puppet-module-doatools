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
    ensure => absent,
    region => us-east-1,
  }

  [
    'doatools_a',
    'doatools_b',
    'doatools_c'
  ].each | $s | {
    subnet { $s :
      ensure => absent,
      region => 'us-east-1',
    }

    Security_group['doatools2']->Subnet[ $s]
    Subnet[ $s]->Vpc['doatools']
  }

  security_group { 'doatools2':
    ensure => absent,
    region => 'us-east-1',
  }

  internet_gateway { 'doatools':
    ensure => absent,
    region => 'us-east-1',
  }

  Internet_gateway['doatools']->Vpc['doatools']

}
