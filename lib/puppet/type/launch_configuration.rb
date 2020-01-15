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

Puppet::Type.newtype(:launch_configuration) do
  ensurable

  autorequire(:security_group) do
    if self[:ensure] == :present
      self[:security_groups]
    end
  end

  autobefore(:security_group) do
    if self[:ensure] == :absent
      self[:security_groups]
    end
  end

  autorequire(:iam_instance_profile) do
    if self[:ensure] == :present
      self[:iam_instance_profile]
    end
  end

  autobefore(:iam_instance_profile) do
    if self[:ensure] == :absent
      self[:iam_instance_profile]
    end
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

  newproperty(:revision) do
    validate do |value|
      fail("revision is a read only property")
    end
  end

  newproperty(:image) do
  end

  newproperty(:instance_type) do
  end

  newproperty(:iam_instance_profile) do
  end


  newproperty(:security_groups, :array_matching => :all) do
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:userdata) do
  end

  newproperty(:ssh_key_name) do
  end

  newproperty(:public_ip) do
    newvalues(:enabled, :disabled)
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end

  end

  newproperty(:image_disks) do
    defaultto {}
    def insync?(is)
      puts "should=#{@should}"
      puts "is=#{is}"

      # do we have a disk defined
      no_disk_defined = @should.length == 0 and is.keys.length == 0

      result = ( @should.length == 0 and is.keys.length == 0 ) or
        @should.all?{|s|
          # all top level keys are devices. These lists should contain the same keys if we are in sync
          should_devices_present = s.keys.all?{|device| is.has_key? device}
          is_devices_present = is.keys.all?{|device| s.has_key? device}
          puts "should_devices_present=#{should_devices_present}"
          puts "is_devices_present=#{is_devices_present}"
          all_keys_match = s.keys.all?{|device|
            # then we need to check each device in turn and make sure that all should keys and value are identical in is.
            s[device].keys.all?{|param|
              is_has_key = is[device].has_key? param
              puts "device=#{device} testing key param=#{param} is_has_key=#{is_has_key}"
              is_key_present = is[device][param] == s[device][param] if is_has_key
              puts "device=#{device} testing key param=#{param} is=#{is[device][param]} s=#{s[device][param]}"

              is[device].has_key? param and is[device][param] == s[device][param]
            }
          }
          puts "all_keys_match=#{all_keys_match}"
          should_devices_present and is_devices_present and all_keys_match
        }
      puts "result=#{result}"
      result
    end

  end

  newproperty(:extra_disks, :array_matching => :all) do
    defaultto []
  end

end

