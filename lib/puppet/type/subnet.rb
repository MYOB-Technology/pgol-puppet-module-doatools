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

Puppet::Type.newtype(:subnet) do
  ensurable

  autorequire(:vpc) do
    self[:vpc]
  end

  newparam(:name, :namevar => true) do
  end

  newproperty(:vpc) do

  end

  #  read only properties...
  newproperty(:region) do
    defaultto 'us-east-1'
    validate do |value|
      regions = PuppetX::IntechWIFI::Constants.Regions
      fail("Unsupported AWS Region #{value} we support the following regions #{regions}") unless regions.include? value
    end
  end

  newproperty(:availability_zone) do
    defaultto 'a'
    validate do |value|
      fail("Invalid availability zone #{value}") unless PuppetX::IntechWIFI::Constants.AvailabilityZones.include? value
    end
  end

  newproperty(:environment) do
  end

  newproperty(:cidr) do
    defaultto '10.0.0.0/8'
    validate do |value|
      #  Its not worth doing a lot of validation as AWS will reject invalid strings.

      #  Reject any invalid characters
      fail("Invalid CIDR #{value}") unless value =~ /^[0-9\.\/]+$/

    end
  end

  newproperty(:public_ip) do
    validate do |value|
      fail("The subnet public property can be [true|false]") unless (PuppetX::IntechWIFI::Logical.logical_true(value) or PuppetX::IntechWIFI::Logical.logical_false(value))
    end
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end
  end

  newproperty(:routetable) do

  end

  newproperty(:nacl) do

  end


end
