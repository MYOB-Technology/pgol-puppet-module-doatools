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
  rds_subnet_group {'doatools-rdsnet':
    region  => 'us-east-1',
    subnets => [
      'doatools_a',
      'doatools_b',
      'doatools_c'
    ]
  }

  rds { 'doatools':
    region          => 'us-east-1',
    engine          => 'mysql',
    db_subnet_group => 'doatools-rdsnet',
    master_username => 'admin',
    master_password => 'Password!',
    database        => 'doatools_db',
    public_access   => true,
    instance_type   => 'db.t2.micro',
    storage_size    => '50',
  }
}