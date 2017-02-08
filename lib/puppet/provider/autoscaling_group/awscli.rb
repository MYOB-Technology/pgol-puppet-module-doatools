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

Puppet::Type.type(:autoscaling_group).provide(:awscli) do
  commands :awscli => "aws"


  def create
    args = [
        "autoscaling", "create-auto-scaling-group", "--region", resource[:region],
        "--auto-scaling-group-name", resource[:name]
    ]

    args << ["--desired-capacity", resource[:desired_instances]]
    args << ["--min-size", resource[:minimum_instances]]
    args << ["--max-size", resource[:maximum_instances]]
    args << ["--launch-configuration-name",
             PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name(
                 [resource[:region]], resource[:launch_configuration]){|*arg| awscli(*arg)
             }["LaunchConfigurationName"]]
    args << ["--vpc-zone-identifier", resource[:subnets].map{|subnet|
      PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], 'subnet', subnet){|*arg| awscli(*arg)}
    }.join(",")]
    args << ["--health-check-grace-period", resource[:healthcheck_grace]] unless resource[:healthcheck_grace].nil?
    args << ["--health-check-type", resource[:healthcheck_type]] unless resource[:healthcheck_type].nil?

    awscli(args.flatten)

    @property_hash[:region] = resource[:region]
    @property_hash[:desired_instances] = resource[:desired_instances]
    @property_hash[:minimum_instances] = resource[:minimum_instances]
    @property_hash[:maximum_instances] = resource[:maximum_instances]
    @property_hash[:launch_configuration] = resource[:launch_configuration]
    @property_hash[:healthcheck_type] = resource[:healthcheck_type] unless resource[:healthcheck_type].nil?
    @property_hash[:healthcheck_grace] = resource[:healthcheck_grace] unless resource[:healthcheck_grace].nil?

  end

  def destroy

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

    debug("searching regions=#{regions} for autoscaling_group=#{resource[:name]}\n")

    search = PuppetX::IntechWIFI::AwsCmds.find_autoscaling_by_name(regions, resource[:name]) do | *arg |
      awscli(*arg)
    end

    data = search[:data]

    @property_hash[:name] = resource[:name]
    @property_hash[:region]= search[:region]

    @property_hash[:desired_instances] = data["DesiredCapacity"]
    @property_hash[:minimum_instances] = Integer(data["MinSize"])
    @property_hash[:maximum_instances] = Integer(data["MaxSize"])
    @property_hash[:launch_configuration] = PuppetX::IntechWIFI::Autoscaling_Rules.base_lc_name(data["LaunchConfigurationName"])
    @property_hash[:subnets] = data["VPCZoneIdentifier"].split(",").map{|subnet|
      PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'subnet', subnet){|*arg| awscli(*arg)}
    }
    @property_hash[:healthcheck_grace] = Integer(data["HealthCheckGracePeriod"])
    @property_hash[:healthcheck_type] = data["HealthCheckType"]

    # Do we need to update the launch_configuration?
    if PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name([@property_hash[:region]], @property_hash[:launch_configuration]){|*arg| awscli(*arg)}["LaunchConfigurationName"] != data["LaunchConfigurationName"]
      self.launch_configuration = @property_hash[:launch_configuration]
      @property_hash[:launch_configuration] = @property_hash[:launch_configuration] + "_expired"
    end

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def flush
    if !@property_flush.nil? and @property_flush.length > 0
      args = [
          "autoscaling", "update-auto-scaling-group", "--region", @property_hash[:region],
          "--auto-scaling-group-name", @property_hash[:name]
      ]

      args << ["--desired-capacity", @property_flush[:desired_instances]] unless @property_flush[:desired_instances].nil?
      args << ["--min-size", @property_flush[:minimum_instances]] unless @property_flush[:minimum_instances].nil?
      args << ["--max-size", @property_flush[:maximum_instances]] unless @property_flush[:maximum_instances].nil?
      args << ["--launch-configuration-name", PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name(
          [@property_hash[:region]], @property_flush[:launch_configuration]){|*arg| awscli(*arg)
      }["LaunchConfigurationName"]] unless @property_flush[:launch_configuration].nil?
      args << ["--vpc-zone-identifier", @property_flush[:subnets].map{|subnet|
        PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'subnet', subnet){|*arg| awscli(*arg)}
      }] unless @property_flush[:subnets].nil?
      args << ["--health-check-grace-period", @property_flush[:healthcheck_grace]] unless @property_flush[:healthcheck_grace].nil?
      args << ["--health-check-type", @property_flush[:healthcheck_type]] unless @property_flush[:healthcheck_type].nil?

      awscli(args.flatten)
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
  def desired_instances=(value)
    @property_flush[:desired_instances] = value
  end
  def minimum_instances=(value)
    @property_flush[:minimum_instances] = value
  end
  def maximum_instances=(value)
    @property_flush[:maximum_instances] = value
  end
  def launch_configuration=(value)
    @property_flush[:launch_configuration] = value
  end
  def subnets=(value)
    @property_flush[:subnets] = value
  end
  def healthcheck_grace=(value)
    @property_flush[:healthcheck_grace] = value
  end
  def healthcheck_type=(value)
    @property_flush[:healthcheck_type] = value
  end

end
