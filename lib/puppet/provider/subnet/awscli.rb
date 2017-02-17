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

Puppet::Type.type(:subnet).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create
    #  Ensure the VPC already exists, and get its vpcid.
    begin
      @property_hash[:vpcid] = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], "vpc", resource[:vpc]) do | *arg |
        awscli(*arg)
      end
    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      fail("We cannot created this subnet, unless the vpc=>#{resource[:vpc]} already exists.")
    end


    subnet = JSON.parse(awscli('ec2', 'create-subnet', '--region', resource[:region], '--availability-zone', PuppetX::IntechWIFI::Constants.AvailabilityZone(resource[:region], resource[:availability_zone]), '--vpc-id', @property_hash[:vpcid], '--cidr-block', resource[:cidr]))
    @property_hash[:subnetid] = subnet["Subnet"]["SubnetId"]
    @property_hash[:region] = resource[:region]
    @property_hash[:cidr] = subnet["Subnet"]["CidrBlock"]
    @property_hash[:availability_zone] = resource[:availability_zone]

    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:subnetid], '--tags', "Key=Name,Value=#{resource[:name]}", "Key=Environment,Value=#{resource[:environment]}")

    if resource[:public_ip] then
      @property_hash[:public_ip] = PuppetX::IntechWIFI::Logical.logical(resource[:public_ip])
      set_public_ip(@property_hash[:public_ip])
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    response = awscli('ec2', 'delete-subnet', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid])

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

    search_result = PuppetX::IntechWIFI::AwsCmds.find_tag(regions, 'subnet', "Name", "value" ,resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:ensure] = :present
    @property_hash[:subnetid] = search_result[:tag]["ResourceId"]
    @property_hash[:region] = search_result[:region]
    @property_hash[:name] = resource[:name]

    JSON.parse(awscli('ec2', 'describe-subnets', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid]))["Subnets"].map{|net| extract_values(@property_hash[:region], net) }

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
    @property_hash[:region] = region
    @property_hash[:cidr] = data["CidrBlock"]
    @property_hash[:vpcid] = data["VpcId"]
    @property_hash[:availability_zone] = PuppetX::IntechWIFI::Constants.ZoneName data["AvailabilityZone"]
    @property_hash[:public_ip] = PuppetX::IntechWIFI::Logical.logical(data["MapPublicIpOnLaunch"])

    @property_hash[:vpc] = PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(region, "vpc", @property_hash[:vpcid]) do | *arg |
      awscli(*arg)
    end

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    raise PuppetX::IntechWIFI::Exceptions::VpcNotNamedError , @property_hash[:vpcid]

  end

  def set_public_ip(value)
    awscli('ec2', 'modify-subnet-attribute', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid], '--map-public-ip-on-launch') if PuppetX::IntechWIFI::Logical.logical_true(value)
    awscli('ec2', 'modify-subnet-attribute', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid], '--no-map-public-ip-on-launch') if PuppetX::IntechWIFI::Logical.logical_false(value)
  end



  def flush
    if @property_flush
      if @property_flush[:public_ip] then set_public_ip(@property_flush[:public_ip]) end
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def public_ip=(value)
    @property_flush[:public_ip] = value
  end


end
