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

Puppet::Type.newtype(:autoscaling_group) do
  ensurable

  autorequire(:subnet) do
    if self[:ensure] == :present
      self[:subnets]
    end
  end

  autobefore(:subnet) do
    if self[:ensure] == :absent
      self[:subnets]
    end
  end

  autorequire(:launch_configuration) do
    if self[:ensure] == :present
      self[:launch_configuration]
    end
  end

  autobefore(:launch_configuration) do
    if self[:ensure] == :absent
      self[:launch_configuration]
    end
  end

  autorequire(:internet_gateway) do
    if self[:ensure] == :present
      self[:internet_gateway]
    end
  end

  autobefore(:internet_gateway) do
    if self[:ensure] == :absent
      self[:internet_gateway]
    end
  end

  autorequire(:nat_gateway) do
    if self[:ensure] == :present
      self[:nat_gateway]
    end
  end

  autobefore(:nat_gateway) do
    if self[:ensure] == :absent
      self[:nat_gateway]
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

  newproperty(:desired_instances) do
    munge {|value| Integer(value)}
  end

  newproperty(:minimum_instances) do
    munge {|value| Integer(value)}
  end

  newproperty(:maximum_instances) do
    munge {|value| Integer(value)}
  end

  newproperty(:launch_configuration) do
  end

  newproperty(:load_balancer, :array_matching => :all) do
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:subnets, :array_matching => :all) do
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:healthcheck_grace) do
    munge {|value| Integer(value)}
  end

  newproperty(:healthcheck_type) do
    validate do |value|
      fail("Unsupported Healthcheck type #{value} we support the following types [ :elb, :ec2]") unless [:elb, :ec2].include? value
    end
  end

  newparam(:internet_gateway) do

  end

  newparam(:nat_gateway) do

  end

  newproperty(:tags) do

  end


end