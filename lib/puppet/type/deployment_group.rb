#  Copyright (C) 2017 MYOB / Michael Shaw
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

Puppet::Type.newtype(:deployment_group) do
  ensurable

  autorequire(:autoscaling_group) do
    if self[:ensure] == :present
      self[:autoscaling_groups]
    end
  end

  autobefore(:autoscaling_group) do
    if self[:ensure] == :absent
      self[:autoscaling_groups]
    end
  end

  newparam(:name, :namevar => true) do
  end

  providify
  paramclass(:provider)

  def self.parameters_to_include
    [:provider]
  end

  newparam(:application_name) do
  end

  newproperty(:service_role) do
  end

  newproperty(:autoscaling_groups, :array_matching => :all) do
    def insync?(is)
      is.all?{ |v| @should.include? v} && @should.all?{|v| is.include? v} && provider.checkworks
    end
  end


  #  read only properties...
  newparam(:region) do
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

end
