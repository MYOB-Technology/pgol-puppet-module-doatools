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
  $region='us-east-1',
  $network={

  },
  $roles={

  },
  $ensure=present
)  {
  $network_data = {
    $name => {
      'region' => $region,
      'ensure' => $ensure
    }
  }
  create_resources('doatools::network', $network_data, $network)

  $roles.keys.each | $r| {
    $role_data = {
      $r => {
        'region' => $region,
        'ensure' => $ensure,
        'vpc' => $name,
      }
    }
    create_resources('doatools::role', $role_data, $roles[$r])
  }
}

