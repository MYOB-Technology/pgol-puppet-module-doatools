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
  load_balancer{'doatools':
    ensure => present,
    region => 'us-east-1',
    subnets => [
      'doatools_a',
      'doatools_b',
      'doatools_c'
    ],
    listeners => [
      'http://doatools:80',
#      'https://doatools_tgt:443?certificate=<certificate-arn>'
    ],
    targets => [{
      name => 'doatools',
      port => 80,
      check_interval => 30,
      timeout => 10,
      healthy => 3,
      failed => 2,
      vpc => 'doatools',
    }],
    security_groups => [ "doatools" ]
  }
}
