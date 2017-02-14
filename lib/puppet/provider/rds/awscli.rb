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


require 'json'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/awscmds'
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/network_rules'
require 'puppet_x/intechwifi/rds'

Puppet::Type.type(:rds).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create
    args = [
        'rds', 'create-db-instance',
        '--region', resource[:region],
        '--db-instance-identifier', resource[:name],
        '--engine', resource[:engine],
        '--master-username', resource[:master_username],
        '--master-user-password', resource[:master_password],
    ]

    args << ['--vpc-security-group-ids', @resource[:security_groups].map{ |sg|
      PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@resource[:region], 'security-group', sg){| *arg | awscli(*arg)}
    }] if !@resource[:security_groups].nil?

    # Add in any extra args as needed....
    args << @property_values.map{ |x| args_value(@resource, x[0], x[1]) }.select{|x| !x.nil?}
    args << @property_flags.map{|x| args_flag(@resource, x[0], x[1], x[2])}.select{|x| !x.nil?}

    properties = JSON.parse(awscli(args.flatten))["DBInstance"]

    monitor resource[:region], resource[:name]

    notice("database endpoint is #{PuppetX::IntechWIFI::RDS.find_endpoint(resource[:region], resource[:name]) { |*arg| awscli(*arg)}[:address]}")

  end

  def destroy
    args = [
        'rds', 'delete-db-instance',
        '--region', @property_hash[:region],
        '--db-instance-identifier', @property_hash[:name],
        '--skip-final-snapshot'
    ]
    awscli(args)

    #  Wait for RDS to be deleted.
    monitor @property_hash[:region], @property_hash[:name]

  rescue Exception => e
    #  This is hopefully becuase the RDS instance is deleted.
    debug("We have probably deleted the RDS database.  The following error message should hopefully confirm it.")
    debug(e)
  end

  def exists?
    #
    #  If the puppet manifest is delcaring the existance of a subnet then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    debug("searching regions=#{regions} for subnet=#{resource[:name]}\n")

    data = PuppetX::IntechWIFI::AwsCmds.find_rds_by_name(regions, resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:region] = data[:region]
    data = data[:data][0]

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if data ["DBInstanceStatus"] == "deleting"
    @property_hash[:public_access] = PuppetX::IntechWIFI::Logical.logical(data["PubliclyAccessible"])
    @property_hash[:name] = data["DBInstanceIdentifier"]
    @property_hash[:engine] = data["Engine"]
    @property_hash[:engine_version] = data["EngineVersion"]
    @property_hash[:db_subnet_group] = data["DBSubnetGroup"]["DBSubnetGroupName"]
    @property_hash[:maintenance_window] = data["PreferredMaintenanceWindow"]
    @property_hash[:backup_window] = data["PreferredBackupWindow"]
    @property_hash[:backup_retention_count] = data["BackupRetentionPeriod"]
    @property_hash[:instance_type] = data["DBInstanceClass"]
    @property_hash[:multi_az] = PuppetX::IntechWIFI::Logical.logical(data["MultiAZ"])
    @property_hash[:storage_type] = data["StorageType"]
    @property_hash[:storage_size] = data["AllocatedStorage"]
    @property_hash[:license_model] = data["LicenseModel"]
    @property_hash[:security_groups] = data["VpcSecurityGroups"].select{|sg|  ["active", "adding"].include? sg["Status"]}.map{|sg| PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], 'security-group', sg["VpcSecurityGroupId"]){| *arg | awscli(*arg)} }


    @property_hash[:public_access] = PuppetX::IntechWIFI::Logical.logical(data["PubliclyAccessible"])
    #@property_hash[:iops] = data[""]
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def flush
    if @property_flush and @property_flush.length > 0
      args = [
          'rds', 'modify-db-instance',
          '--region', @property_hash[:region],
          '--db-instance-identifier', @property_hash[:name],
          '--apply-immediately',
          '--allow-major-version-upgrade'
      ]

      # Security groups need translating
      args << ['--vpc-security-group-ids', @property_flush[:security_groups].map{ |sg|
        PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'security-group', sg){| *arg | awscli(*arg)}
      }] if !@property_flush[:security_groups].nil?

      # Add in any extra args as needed....
      args << @property_values.map{ |x| args_value(@property_flush, x[0], x[1]) }.select{|x| !x.nil?}
      args << @property_flags.map{|x| args_flag(@property_flush, x[0], x[1], x[2])}.select{|x| !x.nil?}

      awscli(args.flatten)

      monitor resource[:region], resource[:name]

    end
  end

  def args_value(hash, flag, key)
    hash[key].nil? ? [] : [flag, hash[key]]
  end

  def args_flag(hash, flag_true, flag_false, key)
    hash[key].nil? ? [] : (PuppetX::IntechWIFI::Logical.logical_true(hash[key]) ? flag_true : flag_false)
  end

  def args_flag_true(hash, flag_true, key)
    hash[key].nil? ? [] : hash[key] ? flag_true : nil
  end

  def monitor(region, name, end_status="available", timeout=2700)
    #  First we wait up to 45 seconds for the modifications to start...
    properties = nil
    time = 0
    while time < 45
      sleep(2)
      properties = JSON.parse(awscli('rds', 'describe-db-instances', '--region', region,  '--db-instance-identifier', name))["DBInstances"][0]
      break if properties["DBInstanceStatus"] != "available"
      time += 2
    end

    #  Then we report on statuses until the status is available.
    last_status = nil
    properties = nil
    time = 0
    while time < timeout
      sleep(2)
      properties = JSON.parse(awscli('rds', 'describe-db-instances', '--region', region,  '--db-instance-identifier', name))["DBInstances"][0]
      if properties["DBInstanceStatus"] != last_status
        notice("Status is '#{properties['DBInstanceStatus']}'")
        last_status=properties["DBInstanceStatus"]
      end
      break if properties["DBInstanceStatus"] == end_status
    end
  end



  def initialize(value={})
    super(value)
    @property_flush = {}

    @property_values = [
        ['--db-instance-class',               :instance_type],
        ['--db-subnet-group-name',            :db_subnet_group],
        ['--preferred-maintenance-window',    :maintenance_window],
        ['--preferred-backup-window',         :backup_window],
        ['--backup-retention-period',         :backup_retention_count],
        ['--storage-type',                    :storage_type],
        ['--allocated-storage',               :storage_size],
        ['--license-model',                   :license_model],
        ['--iops',                            :iops],
        ['--engine-version',                  :engine_version]
    ]

    @property_flags = [
        ['--publicly-accessible', '--no-publicly-accessible', :public_access],
        ['--multi-az', '--no-multi-az', :multi_az]
    ]

  end

  mk_resource_methods

  def engine=(value)
    fail("The property [engine] is readonly.") unless @property_hash[:engine].nil?
    @property_flush[:engine] = value
  end

  def engine_version=(value)
    @property_flush[:engine_version] = value
  end

  def db_subnet_group=(value)
    @property_flush[:db_subnet_group] = value
  end

  def maintenance_window=(value)
    @property_flush[:maintenance_window] = value
  end

  def backup_window=(value)
    @property_flush[:backup_window] = value
  end

  def backup_retention_count=(value)
    @property_flush[:backup_retention_count] = value
  end

  def instance_type=(value)
    @property_flush[:instance_type] = value
  end

  def security_groups=(value)
    @property_flush[:security_groups] = value
  end

  def multi_az=(value)
    @property_flush[:multi_az] = value
  end

  def storage_type=(value)
    @property_flush[:storage_type] = value
  end

  def storage_size=(value)
    @property_flush[:storage_size] = value
  end

  def license_model=(value)
    @property_flush[:license_model] = value
  end

  def public_access=(value)
    @property_flush[:public_access] = value
  end

  def iops=(value)
    @property_flush[:iops] = value
  end



end
