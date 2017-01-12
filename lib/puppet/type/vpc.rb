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

Puppet::Type.newtype(:vpc) do
  ensurable

  newparam(:name, :namevar => true) do
  end

  #  read only properties...
  newproperty(:region) do
    defaultto 'us-east-1'
    validate do |value|
      regions = PuppetX::IntechWIFI::Constants.Regions
      fail("Unsupported AWS Region #{value} we support the following regions #{regions}") unless regions.include? value
    end
  end

  newproperty(:cidr) do
    defaultto '192.168.0.0/24'
    validate do |value|
      #  Its not worth doing a lot of validation as AWS will reject invalid strings.

      #  Reject any invalid characters
      fail("Invalid CIDR #{value}") unless value =~ /^[0-9\.\/]+$/

    end
  end

  newproperty(:environment) do
  end

  newproperty(:vpcid) do
  end

  #  managed properties
  newproperty(:dns_hostnames) do
    defaultto :disabled
    validate do |value|
      fail("dns_hostnames valid options are [enabled|disabled] and not '#{value}'") unless (PuppetX::IntechWIFI::Logical.logical_true(value) or PuppetX::IntechWIFI::Logical.logical_false(value))
    end
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end
  end

  newproperty(:dns_resolution) do
    defaultto :enabled
    validate do |value|
      fail("dns_resolution valid options are [enabled|disabled] and not '#{value}'") unless (PuppetX::IntechWIFI::Logical.logical_true(value) or PuppetX::IntechWIFI::Logical.logical_false(value))
    end
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end
  end

  newproperty(:dhcp_options) do
  end

  newproperty(:is_default) do
  end

end

