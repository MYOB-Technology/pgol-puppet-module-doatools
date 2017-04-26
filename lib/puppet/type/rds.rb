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

Puppet::Type.newtype(:rds) do
  desc <<-DESC
  The rds resource models a single AWS RDS database in puppet.

  DESC

  ensurable

  autorequire(:rds_subnet_group) do
    if self[:ensure] == :present
      self[:rds_subnet_group]
    end
  end

  autobefore(:rds_subnet_group) do
    if self[:ensure] == :absent
      self[:rds_subnet_group]
    end
  end

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

  newparam(:name, :namevar => true) do
    desc <<-DESC
    The RDS name must be both unique within this puppet manifest, and unique within the AWS region for this AWS account.
    It must also only iunclude letters, numbers and hyphens.
    DESC
    validate do |value|
      fail("RDS name `#{value}` is not allowed by AWS.") unless /^[a-z][a-z0-9\-]+$/ =~ value
    end
  end

  newparam(:master_username) do
    desc <<-DESC
    The master_username is the top level user account used to access the database engine with (near) admin permisions.
    DESC

  end

  newparam(:master_password) do
    desc <<-DESC
    The master_password is the top level user account password used to access the database engine with (near) admin
    permisions.
    DESC

  end

  newparam(:database) do
    desc <<-DESC
    The database is the name of the default database that is created within the RDS Database server.
    DESC

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

  newparam(:engine) do
    defaultto 'mysql'
    validate do |value|
      engines = PuppetX::IntechWIFI::Constants.RDS_Engines
      fail("Unsupported AWS RDS Engine #{value} we support the following engines #{engines}") unless engines.include? value
    end
  end

  newproperty(:engine_version) do

  end

  newproperty(:rds_subnet_group) do

  end

  newproperty(:maintenance_window) do

  end

  newproperty(:backup_window) do

  end

  newproperty(:backup_retention_count) do

  end

  newproperty(:instance_type) do

  end

  newproperty(:security_groups, :array_matching => :all) do
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end


  newproperty(:multi_az) do
    newvalues(:enabled, :disabled)
    defaultto :enabled
    validate do |value|
      fail("multi_az valid options are [enabled|disabled] and not '#{value}'") unless (PuppetX::IntechWIFI::Logical.logical_true(value) or PuppetX::IntechWIFI::Logical.logical_false(value))
    end
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end

  end

  newproperty(:storage_type) do

  end

  newproperty(:storage_size) do
    munge {|value| Integer(value)}
  end

  newproperty(:license_model) do
    validate do |value|
      licenses = PuppetX::IntechWIFI::Constants.License_Models
      fail("Unsupported AWS RDS Licence model #{value} we support the following models #{licenses}") unless licenses.include? value
    end
  end

  newproperty(:public_access) do
    defaultto :disabled
    validate do |value|
      fail("publicly_available valid options are [enabled|disabled] and not '#{value}'") unless (PuppetX::IntechWIFI::Logical.logical_true(value) or PuppetX::IntechWIFI::Logical.logical_false(value))
    end
    munge do |value|
      PuppetX::IntechWIFI::Logical.logical(value)
    end
  end

  newproperty(:iops) do
    munge {|value| Integer(value)}

  end

end

