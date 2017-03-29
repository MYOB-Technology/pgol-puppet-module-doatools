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
require 'puppet_x/intechwifi/tags_property'

Puppet::Type.newtype(:vpc) do
  desc <<-DESC
  The vpc resource models a single AWS VPC in puppet. Creating a new VPC also brings
  into existance the default route table and security_group, both tagged with the same
  name as the VPC.

  Other networking components that combine to make up the VPC need to declared as seperate resources.

  @example Create a simple VPC
    vpc {'example':
      region => 'us-east-1'
    }

  @example Destroy a VPC
    vpc {'example':
      ensure => absent,
      region => 'us-east-1'
    }

  @example Typical VPC declaration
    vpc {'typical_vpc':
      region        => 'eu-west-1',
      cidr          => '192.168.182.0/23',
      dns_hostnames => enabled,
      is_default    => enabled,
      tags          => {
        owner => 'Marketing',
        role  => 'Keeping the marketing department infrastructure seperate from the developers systems'
      }
    }

  @example JSON tags declaration
    vpc {'complex':
      ensure => present,
      region => 'eu-west-1',
      cidr   => '10.0.1.0/26',
      dns_hostnames => enabled,
      dns_resolution => enabled,
      is_default => false,
      tags => {
        roles => [
          'authenticator',
          'sessions'
        ],
        change_history => [
          {
             date    => '20170328',
             version => '1.4.1',
             notes   => 'patch for issue: EXAP-1043'
          },
          {
             date    => '20170326',
             version => '1.4.0',
             notes   => 'Release 1.4.0'
          }
        ]
      }
    }

  DESC

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:region) do
    defaultto 'us-east-1'
    validate do |value|
      regions = PuppetX::IntechWIFI::Constants.Regions
      fail("Unsupported AWS Region #{value} we support the following regions #{regions}") unless regions.include? value
    end
  end

  newparam(:cidr) do
    desc <<-DESC
    The virtual private cloud's VPC defines the IP address space that can be contained within this VPC.  Subnets will
    only be able to be created using partial address ranges within the scope of this CIDR.
    DESC

    defaultto '192.168.0.0/24'
    validate do |value|
      #  Its not worth doing a lot of validation as AWS will reject invalid strings.

      #  Reject any invalid characters
      fail("Invalid CIDR #{value}") unless value =~ /^[0-9\.\/]+$/

    end
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
    newvalues(:enabled, :disabled)
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

  newproperty(:tags) do
    desc <<-DESC
    The tags property is presented as a hash containing key / value pairs. Values can be
    strings, hashes or arrays. Hashes and arrays are stored in AWS as JSON strings.
    DESC

    defaultto { }

    validate do | value|
      PuppetX::IntechWIFI::Tags_Property.validate_value(value)
    end
    def insync?(is)
      @should.any?{|x| PuppetX::IntechWIFI::Tags_Property.insync?(is, x)}
    end
  end

end

