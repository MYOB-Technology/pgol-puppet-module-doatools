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
require 'puppet_x/intechwifi/exceptions'

module PuppetX
  module IntechWIFI
    module Network_Rules

      def self.AwsToPuppetString(data)
        result = data.map{|egress|
            # Convert the protocol.
            protocol = self.IpProtocolToString(egress["IpProtocol"])

            #  Convert the location.
            locations = self.FormatLocation egress

            #  Convert the ports.
            ports = self.FormatPorts egress

            locations.map{|location| "#{protocol}|#{ports}|#{location}"}
        }.flatten().sort()
        return result
      end


      def self.IpProtocolToString source
        if source == "-1"
          "all"
        else
          source
        end
      end



      def self.FormatLocation data
        if data["IpRanges"].length > 0
          self.FormatLocationFromIpRanges data["IpRanges"]
        # elsif data["UserIdGroupPairs"].length > 0
        #  self.FormatLocationFromGroupPairs data["UserIdGroupPairs"]
        else
          []
        end
      end

      def self.FormatPorts data
        from = data["FromPort"]
        to = data["ToPort"]

        if from and to and from != to
          "#{from}-#{to}"
        elsif from and to
          "#{from}"
        else
          ""
        end
      end

      def self.FormatLocationFromIpRanges source
        #  Take the contents of the IPRanges array and convert into a string fragment.
        source.map{|cidr| "cidr|#{cidr['CidrIp']}"}
      end

      #def self.FormatLocationUserGroupPairs source, region, &aws_command
        #  Yeah, nice weather isnt it?  Lets solve this problem later.
        # sg_name = PuppetX::IntechWIFI::AwsCmds.find_name_by_id region, 'security-group', source, &aws_command
      #  "sg{}"
      #end

    end

  end
end

