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

Puppet::Type.type(:launch_configuration).provide(:awscli) do
  commands :awscli => "aws"

  def create
    #  Since we cannot update properties after creating a launch configuration, we actually create the new launch configuration
    #  when we flush the properties.
    @property_hash[:index] = 0
    @property_hash[:name] = resource[:name]
    self.image = resource[:image]
    self.instance_type = resource[:instance_type]
    self.security_groups = resource[:security_groups]
    self.userdata = resource[:userdata]
    self.ssh_key_name = resource[:ssh_key_name]

    @property_hash[:region] = resource[:region]

  end

  def destroy
    lcs = JSON.parse(awscli('autoscaling', 'describe-launch-configurations', '--region', @property_hash[:region]))["LaunchConfigurations"].select{|l|
      PuppetX::IntechWIFI::Autoscaling_Rules.is_valid_lc_name?(name, l['LaunchConfigurationName'] )
    }.reduce([]){|memo, lc| memo << lc }

    lcs.each{|lc| awscli("autoscaling", "delete-launch-configuration", '--region', @property_hash[:region], "--launch-configuration-name", lc['LaunchConfigurationName']) }

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

    debug("searching regions=#{regions} for launch_configuration=#{resource[:name]}\n")

    #  launch configurations cannot be modified in place. When we change properties we have to create a new one. to handle this
    #  we add a sequential 6 digit number on the end of the launch configuration.

    launch_config = PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name(regions,resource[:name]) {| *arg | awscli(*arg) }

    @property_hash[:ensure] = :present
    #!TODO: Region should really be extracted from the ARN value.
    @property_hash[:region] = resource[:region]
    @property_hash[:name] = resource[:name]

    @property_hash[:index] = PuppetX::IntechWIFI::Autoscaling_Rules.index(launch_config["LaunchConfigurationName"])
    @property_hash[:image] = launch_config["ImageId"]
    @property_hash[:instance_type] = launch_config["InstanceType"]
    @property_hash[:security_groups] = launch_config["SecurityGroups"].map{|id| PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'security-group', id){| *arg | awscli(*arg) }}
    @property_hash[:userdata] = Base64.decode64(launch_config["UserData"])
    @property_hash[:ssh_key_name] = launch_config["KeyName"]

    # print "launch_config = #{launch_config}\n"
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def extract_values(region, data)

  end

  def flush
    if @property_flush and @property_flush.length > 0
      # We need to create a new launch configuration here every time there is a property change
      @property_flush[:index] = @property_hash[:index] + 1
      new_name = [@property_hash[:name], PuppetX::IntechWIFI::Autoscaling_Rules.encode_index(@property_flush[:index])].join

      args = [
          "autoscaling",
          "create-launch-configuration",
          "--region", value(:region),
          "--launch-configuration-name", new_name,
          "--image-id", value(:image),
          "--instance-type", value(:instance_type)
      ]
      #  Add in security groups
      if (value(:security_groups).nil? == false) and (value(:security_groups).length > 0)
        args << [
            "--security-groups",
            value(:security_groups).map{|sg|
              PuppetX::IntechWIFI::AwsCmds.find_id_by_name(value(:region), 'security-group', sg){| *arg | awscli(*arg) }
            }
        ]
      end
      if (value(:userdata).nil? == false) and (value(:userdata).length > 0)
        args << [
            "--user-data", "#{value(:userdata)}"
        ]
      end
      if (value(:ssh_key_name).nil? == false) and (value(:ssh_key_name).length > 0)
        args << [
            "--key-name", "#{value(:ssh_key_name)}"
        ]
      end


      #  Ensure we have a flat array...
      args.flatten

      #  Create the new launch_configuration
      awscli(args)

      lcs = JSON.parse(awscli('autoscaling', 'describe-launch-configurations', '--region', @property_hash[:region]))["LaunchConfigurations"].select{|l|
        PuppetX::IntechWIFI::Autoscaling_Rules.is_valid_lc_name?(name, l['LaunchConfigurationName'] ) }.map{|l| l['LaunchConfigurationName']}.sort

      if lcs.length > 5
        lcs.slice(0, lcs.length - 5).each{|lc|
          awscli("autoscaling", "delete-launch-configuration", '--region', value(:region), "--launch-configuration-name", lc)
        }
      end

    end
  end

  def value key
    if @property_flush[key].nil?
      @property_hash[key]
    else
      @property_flush[key]
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def region=(value)
    @property_flush[:region] = value
  end

  def instance_type=(value)
    @property_flush[:instance_type] = value
  end

  def image=(value)
    @property_flush[:image] = value
  end

  def security_groups=(value)
    @property_flush[:security_groups] = value
  end

  def userdata=(value)
    @property_flush[:userdata] = value
  end

  def ssh_key_name=(value)
    @property_flush[:ssh_key_name] = value
  end

  def keep_versions=(value)
    @property_flush[:keep_versions] = value
  end


end