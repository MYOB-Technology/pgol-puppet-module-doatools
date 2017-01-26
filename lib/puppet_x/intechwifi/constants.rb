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

      @@OS_Description_Map = [
          { :label => 'windows2012r2', :description => 'Microsoft Windows Server 2012 R2 RTM 64-bit Locale English AMI provided by Amazon'},
          { :label => 'windows2016', :description => ''},
          { :label => 'centos7', :description => ''},
          { :label => 'amzn-linux', :description => ''},
      ]

      @@principal_map = [
          {:key => 'ec2', :value => "ec2.amazonaws.com" },
      ]

      def self.PrincipalKey value
        @@principal_map.select{|p| p[:value] == value}[0][:key]
      end

      def self.PrincipalValue key
        @@principal_map.select{|p| p[:key] == key}[0][:value]
      end

      @@rds_engines = [
          "mysql",
          "mariadb",
          "oracle-se1",
          "oracle-se2",
          "oracle-se",
          "oracle-ee",
          "sqlserver-ee",
          "sqlserver-se",
          "sqlserver-ex",
          "sqlserver-web",
          "postgres",
          "aurora"
      ]

      def self.RDS_Engines
        @@rds_engines
      end

    end
  end
end

