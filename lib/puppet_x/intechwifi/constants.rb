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

module PuppetX
  module IntechWIFI 
    module Constants

      #  possible later feature to override this list from an environment variable as an optimisation
      @@regions = [
        "us-east-1",
        "us-east-2",
        "us-west-1",
        "us-west-2",
        "ca-central-1",
        "eu-west-1",
        "eu-central-1",
        "eu-west-2",
        "ap-northeast-1",
        "ap-northeast-2",
        "ap-southeast-1",
        "ap-southeast-2",
        "ap-south-1",
        "sa-east-1"
      ]

      @@zone_map = [
          {:az => 'a', :zone => "a" },
          {:az => 'b', :zone => "b" },
          {:az => 'c', :zone => "c" },
      ]

      def self.Regions
        @@regions
      end

      def self.AvailabilityZones
        @@zone_map.collect{|zm| zm[:zone] }
      end

      def self.ZoneName aws_az
        if aws_az.length > 1
          region = aws_az.chop
          fail("Unsupported region (#{region} detected.") if !self.Regions.include? region
        end
        @@zone_map.select{|zm| zm[:az] == aws_az[-1]}.collect{|zm| zm[:zone]}[0]
      end

      def self.AvailabilityZone region, zone
        "#{region}#{@@zone_map.select{|zm| zm[:zone] == zone}.collect{|zm| zm[:az]}[0]}"
      end

    end
  end
end

