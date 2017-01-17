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
require 'puppet_x/intechwifi/awscmds'

module PuppetX
  module IntechWIFI
    module Network_Rules

      def self.AwsToPuppetString(data, region, &awscmd)
        result = data.map{|gress|
            # Convert the protocol.
            protocol = self.IpProtocolToString(gress["IpProtocol"])

            #  Convert the location.
            locations = self.FormatLocation gress, region, &awscmd

            #  Convert the ports.
            ports = self.FormatPorts gress

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



      def self.FormatLocation data, region, &awscmd
        result = []
        result << self.FormatLocationFromIpRanges(data["IpRanges"]) if data["IpRanges"].length > 0
        result << self.FormatLocationFromGroupPairs(data["UserIdGroupPairs"], region, &awscmd)  if data["UserIdGroupPairs"].length > 0
        result.flatten
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

      def self.FormatLocationFromGroupPairs source, region, &awscmd
        #  Yeah, nice weather isnt it?  Lets solve this problem later.
        source.map{|location|
          location_sgid = location['GroupId']
          sg_name =  PuppetX::IntechWIFI::AwsCmds.find_name_by_id(region, 'security-group', location_sgid, &awscmd)
          "sg|#{sg_name}"
        }
      end

    end

  end
end

