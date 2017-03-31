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

require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/network_rules'

Puppet::Type.newtype(:route_table_routes) do
  ensurable

  autorequire(:route_table) do
    self[:name]
  end

  newparam(:name, :namevar => true) do

  end

  #  read only properties...
  newproperty(:region) do
    desc <<-DESC
    The region parameter is required for all puppet actions on this resource. It needs to follow the 'us-east-1' style,
    and not the 'N. Virginia' format. Changing this paramter does not move the resource from one region to another,
    but it may create a new resource in the new region, and will completely ignore the existing resource in the old
    region
    DESC
    defaultto 'us-east-1'
    validate do |value|
      regions = PuppetX::IntechWIFI::Constants.Regions
      fail("Unsupported AWS Region #{value} we support the following regions #{regions}") unless regions.include? value
    end
  end

  newproperty(:routes, :array_matching => :all) do
    validate do | value|
      splits = value.split('|')
      fail("route should be in the format 'cidr|<type>|<instance>'") unless splits.length == 3
      fail("route type can be one of [nat|igw|blackhole]") unless ['nat', 'igw', 'blackhole'].include? splits[1]
    end
    def insync?(is)
      @should.all?{|v| is.any?{ |x| PuppetX::IntechWIFI::Network_Rules.RouteRuleMatch(v, x) } } and
          is.all?{|v| @should.any?{ |x| PuppetX::IntechWIFI::Network_Rules.RouteRuleMatch(x, v) } }
    end
  end

end
