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

    create_update_tags(resource[:tags], resource[:name], resource[:region]) unless resource[:tags].nil?

    add_loadbalancer(resource[:region], resource[:name], resource[:load_balancer]) unless resource[:load_balancer].nil?

    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:desired_instances] = resource[:desired_instances]
    @property_hash[:minimum_instances] = resource[:minimum_instances]
    @property_hash[:maximum_instances] = resource[:maximum_instances]
    @property_hash[:launch_configuration] = resource[:launch_configuration]
    @property_hash[:healthcheck_type] = resource[:healthcheck_type] unless resource[:healthcheck_type].nil?
    @property_hash[:healthcheck_grace] = resource[:healthcheck_grace] unless resource[:healthcheck_grace].nil?
    @property_hash[:tags] = resource[:tags]

  end

  def destroy
    args = [
        "autoscaling", "delete-auto-scaling-group", "--region", resource[:region],
        "--auto-scaling-group-name", resource[:name],
        "--force"
    ]
    awscli(args.flatten)

  end

  def exists?
    puts 'IN EXISTS'
    #
    #  If the puppet manifest is delcaring the existance of a subnet then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    debug("searching regions=#{regions} for autoscaling_group=#{resource[:name]}\n")

    puts "finding ASG #{resource[:name]}"
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
    puts "finding subnets"
    @property_hash[:subnets] = data["VPCZoneIdentifier"].split(",").map{|subnet|
      PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], 'subnet', subnet){|*arg| awscli(*arg)}
    }
    @property_hash[:healthcheck_grace] = Integer(data["HealthCheckGracePeriod"])
    @property_hash[:healthcheck_type] = data["HealthCheckType"]
    @property_hash[:tags] = convert_aws_to_puppet_tags(data['Tags'])
    puts "finding ELB"
    @property_hash[:load_balancer] = PuppetX::IntechWIFI::Autoscaling_Rules.get_load_balancer(@property_hash[:name], @property_hash[:region]){|*arg| awscli(*arg)}


    # Do we need to update the launch_configuration?
    if PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name([@property_hash[:region]], @property_hash[:launch_configuration]){|*arg| awscli(*arg)}["LaunchConfigurationName"] != data["LaunchConfigurationName"]
      self.launch_configuration = @property_hash[:launch_configuration]
      @property_hash[:launch_configuration] = @property_hash[:launch_configuration] + "_expired"
    end

    puts 'DONE EXISTS'
    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    puts 'none found'
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    puts 'too many found'
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
      create_update_tags(@property_flush[:tags], @property_hash[:name], @property_hash[:region]) if @property_flush.has_key?(:tags)

      update_loadbalancer(@property_hash[:region], @property_hash[:name], @property_hash[:load_balancer], @property_flush[:load_balancer]) if @property_flush.has_key?(:load_balancer)
    end
  end

  def update_loadbalancer(region, autoscaling_name, from, to)
    remove_loadbalancer(region, autoscaling_name, from) if !from.nil?
    add_loadbalancer(region, autoscaling_name, to) if !to.nil?
  end

  def add_loadbalancer(region, autoscaling_name, target_group)
    args = [
        'autoscaling', 'attach-load-balancer-target-groups',
        '--region', region,
        '--auto-scaling-group-name', autoscaling_name,
        '--target-group-arns', PuppetX::IntechWIFI::AwsCmds.find_elb_target_by_name(target_group, region){|*arg| awscli(*arg)}
    ]

    awscli(args.flatten)

  end

  def remove_loadbalancer(region, autoscaling_name, target_group)
    args = [
        'autoscaling', 'detach-load-balancer-target-groups',
        '--region', region,
        '--auto-scaling-group-name', autoscaling_name,
        '--target-group-arns', PuppetX::IntechWIFI::AwsCmds.find_elb_target_by_name(target_group, region){|*arg| awscli(*arg)}
    ]

    awscli(args.flatten)

  end

  def create_update_tags(tags, asg_name, region)
    args = [
      "autoscaling", "create-or-update-tags", "--region", region,
      "--tags", convert_puppet_to_aws_tags(asg_name, tags)
    ]
    awscli(args.flatten)
  end

  def convert_puppet_to_aws_tags(asg_name, tags)
    tags.map { |key, value| 
      {
        'ResourceId' => asg_name,
        'ResourceType' => 'auto-scaling-group',
        'Key' =>  key,
        'Value' => value,
        'PropagateAtLaunch': true
      }.to_json
    }
  end

  def convert_aws_to_puppet_tags(tags)
    tags.map { |tag| { tag['Key'] => tag['Value'] } }
        .reduce({}){ |hash, kv| hash.merge(kv)  }
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
  def load_balancer=(value)
    @property_flush[:load_balancer] = value
  end
  def healthcheck_grace=(value)
    @property_flush[:healthcheck_grace] = value
  end
  def healthcheck_type=(value)
    @property_flush[:healthcheck_type] = value
  end
  def tags=(value)
    @property_flush[:tags] = value
  end

end
