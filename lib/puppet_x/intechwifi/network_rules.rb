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
        puts "FORMAT PORTS #{data}"
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

      def self.MakeCidr(cidr, index, total)
        cidr_array = cidr.split("/")
        cidr_base = cidr_array[0]
        cidr_range = cidr_array[1]

        # Convert the cidr_base into a number.
        cidr_integer = cidr_base.split(".").map(&:to_i).reduce(0) { |sum, num| (sum << 8) + num }

        # Calculate the size of each cidr.
        bitshift = 0
        loop do
          offset = 1 << bitshift
          break unless offset < total
          bitshift += 1
        end

        new_cidr_size = cidr_range.to_i + bitshift
        new_base = cidr_integer + (index << (32 - new_cidr_size))

        (new_base >> 24).to_s + "." + (new_base >> 16 & 0xFF).to_s + "." + (new_base >> 8 & 0xFF).to_s + "." + (new_base & 0xFF).to_s + "/" + new_cidr_size.to_s
      end

      def self.RouteRuleMatch(declared, detected)
        should = declared.split('|')
        is = detected.split('|')

        cidr_match = (should[0] == is[0])
        target_match = ((should[1] == is[1]) and (should[2] == is[2]))
        blackhole = should[1] == 'blackhole'
        cidr_match and (target_match or blackhole)
      end


    end

  end
end

