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

Puppet::Type.type(:security_group).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create
    #  Ensure the VPC already exists, and get its vpcid.
    begin
      @property_hash[:vpcid] = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], "vpc", resource[:vpc]) do | *arg |
        awscli(*arg)
      end
    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      fail("We cannot created this security group, unless the vpc=>#{resource[:vpc]} already exists.")
    end

    @property_hash[:sgid] = JSON.parse(awscli('ec2', 'create-security-group', '--region', resource[:region], '--group-name', resource[:name], '--description', resource[:description], '--vpc-id', @property_hash[:vpcid]))["GroupId"]
    @property_hash[:region] = resource[:region]
    @property_hash[:description] = resource[:description]
    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:sgid], '--tags', "Key=Name,Value=#{resource[:name]}")

    @property_hash[:tags] = resource[:tags]
    PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:sgid], {}, @property_hash[:tags]){| *arg | awscli(*arg)} if !@property_hash[:tags].nil?


    @property_hash[:ensure] = :present

  end

  def destroy()
    destroy_internal
  rescue Exception => e
    fail(e)
  end

  def destroy_internal(count=0, max_count=3)
    response = awscli('ec2', 'delete-security-group', '--region', @property_hash[:region], '--group-id', @property_hash[:sgid])
  rescue Puppet::ExecutionFailure => e
    if (count < 3) and (e.to_s.include? "DependencyViolation")
      info("Dependency violation #{count + 1} of #{max_count} , Retrying in 45 seconds...")
      sleep 45
      destroy_internal(count + 1, max_count)
    else
      fail(e)
    end

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

    debug("searching regions=#{regions} for security_group=#{resource[:name]}\n")

    search_result = PuppetX::IntechWIFI::AwsCmds.find_tag(regions, 'security-group', "Name", "value" ,resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:ensure] = :present
    @property_hash[:sgid] = search_result[:tag]["ResourceId"]
    @property_hash[:region] = search_result[:region]
    @property_hash[:name] = resource[:name]

    JSON.parse(awscli('ec2', 'describe-security-groups', '--region', @property_hash[:region], '--group-id', @property_hash[:sgid]))["SecurityGroups"].map{|data| extract_values(@property_hash[:region], data) }
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def extract_values(region, data)
    @property_hash[:tags] = PuppetX::IntechWIFI::Tags_Property.parse_tags(data["Tags"])

    @property_hash[:vpcid] = data["VpcId"]
    @property_hash[:description] = data["Description"]
    begin
      @property_hash[:vpc] = PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(region, "vpc", @property_hash[:vpcid]) do | *arg |
        awscli(*arg)
      end
    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      raise PuppetX::IntechWIFI::Exceptions::VpcNotNamedError , @property_hash[:vpcid]
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def flush
    if @property_flush
      PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:sgid], @property_hash[:tags], @property_flush[:tags]){| *arg | awscli(*arg)} if !@property_flush[:tags].nil?
    end
  end


  mk_resource_methods

  def tags=(value)
    @property_flush[:tags] = value
  end

end
