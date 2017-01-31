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

require 'json'

module PuppetX
  module IntechWIFI
    module RDS
      def RDS.find_endpoint(region, name, &aws_command)
        result = JSON.parse(aws_command.call('rds', 'describe-db-instances', '--region', region, '--db-instance-identifier', name))

        {
            :address => result["DBInstances"][0]["Endpoint"]["Address"],
            :port    => result["DBInstances"][0]["Endpoint"]["Port"]
        }
      end
    end
  end
end

