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

Puppet::Type.type(:internet_gateway).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create
    igw = JSON.parse(awscli('ec2', 'create-internet-gateway', '--region', resource[:region]))["InternetGateway"]
    @property_hash[:igwid] = igw["InternetGatewayId"]
    @property_hash[:region] = resource[:region]
    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:igwid], '--tags', "Key=Name,Value=#{resource[:name]}", "Key=Environment,Value=#{resource[:environment]}")

    #
    #  Internet Gateways are created outside of a VPC, and then can be attached or detached from VPC's at any time.
    #
    if resource[:vpc] then
      set_vpc(resource[:region], resource[:vpc])
    end

    @property_hash[:ensure] = :present

  end

  def destroy
    if @property_hash[:vpc] then
      awscli('ec2', 'detach-internet-gateway', '--region', resource[:region], '--internet-gateway-id', @property_hash[:igwid], '--vpc-id', @property_hash[:vpcid])
    end

    awscli('ec2', 'delete-internet-gateway', '--region', resource[:region], '--internet-gateway-id', @property_hash[:igwid])
    @property_hash.clear
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

    search_result = PuppetX::IntechWIFI::AwsCmds.find_tag(regions, 'internet-gateway', "Name", "value" ,resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:ensure] = :present
    @property_hash[:igwid] = search_result[:tag]["ResourceId"]
    @property_hash[:region] = search_result[:region]
    @property_hash[:name] = resource[:name]

    JSON.parse(awscli('ec2', 'describe-internet-gateways', '--region', @property_hash[:region], '--internet-gateway-ids', @property_hash[:igwid]))["InternetGateways"].map{|item| extract_values(@property_hash[:region], item) }


    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def extract_values(region, data)
    tags = data["Tags"]

    if tags
      tags.each do |tag|
        if tag["Key"] == "Name"
          fail("VPC name tag value=#{tag["Value"]} does not match name=#{resource[:name]}.") unless tag['Value'] == resource[:name]
        end
        if tag["Key"] == "Environment"
          @property_hash[:environment] = tag["Value"]
        end
      end
    end

    attachments = data["Attachments"]
    if attachments.length == 1
      @property_hash[:vpcid] = attachments[0]["VpcId"]
      @property_hash[:vpc] = PuppetX::IntechWIFI::AwsCmds.find_name_by_id(region, "vpc", @property_hash[:vpcid]) do | *arg |
        awscli(*arg)
      end
    end

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    raise PuppetX::IntechWIFI::Exceptions::VpcNotNamedError , @property_hash[:vpcid]

  end

  def set_vpc(region, vpc)
    @property_hash[:vpcid] = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(region, "vpc", vpc) do | *arg |
      awscli(*arg)
    end
    @property_hash[:vpc] = vpc
    awscli('ec2', 'attach-internet-gateway', '--region', resource[:region], '--internet-gateway-id', @property_hash[:igwid], '--vpc-id', @property_hash[:vpcid])
  end

  def flush
    if @property_flush
      if @property_flush[:vpc] then set_vpc(@property_hash[:region], @property_flush[:vpc]) end
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def vpc=(value)
    @property_flush[:vpc] = value
  end


end