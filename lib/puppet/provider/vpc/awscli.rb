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

#
#  The awscli provider for VPC's
#

#
#  This provider obtains resources on the fly, rather than caches the entire list of VPC's.  This provides significant performance improvements
#  when the region is part of the manifest declaration, and only a few VPC's are declared.
#

Puppet::Type.type(:vpc).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create
    vpc = JSON.parse(awscli('ec2', 'create-vpc', '--region', resource[:region], '--cidr-block', resource[:cidr]))
    @property_hash[:vpcid] = vpc["Vpc"]["VpcId"]
    @property_hash[:region] = resource[:region]
    @property_hash[:cidr] = resource[:cidr]

    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:vpcid], '--tags', "Key=Name,Value=#{resource[:name]}", "Key=Environment,Value=#{resource[:environment]}")
    if resource[:dns_hostnames] then @property_flush[:dns_hostnames] = resource[:dns_hostnames] end
    if resource[:dns_resolution] then @property_flush[:dns_resolution] = resource[:dns_resolution] end
    @property_hash[:ensure] = :present

  end

  def destroy
    response = awscli('ec2', 'delete-vpc', '--region', @property_hash[:region], '--vpc-id', @property_hash[:vpcid])
    debug("Clearing vpc-id cache for #{name}\n")
    PuppetX::IntechWIFI::AwsCmds.clear_vpc_tag_cache @property_hash[:name]
    @property_hash.clear
  end

  def exists?
    result = false

    #
    #  If the puppet manifest is delcaring the existance of a VPC then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    debug("searching regions=#{regions} for vpc=#{resource[:name]}\n")

    search_result = PuppetX::IntechWIFI::AwsCmds.find_vpc_tag(regions, resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:ensure] = :present
    @property_hash[:vpcid] = search_result[:tag]["ResourceId"]
    @property_hash[:region] = search_result[:region]
    @property_hash[:name] = resource[:name]

    JSON.parse(awscli('ec2', 'describe-vpcs', '--region', @property_hash[:region], '--vpc-id', @property_hash[:vpcid]))["Vpcs"].map{|v| extract_values(@property_hash[:region], v) }

    true

  rescue PuppetX::IntechWIFI::Exceptions::VpcNotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def extract_values(region, vpc)
    tags = vpc["Tags"]

    if tags
      tags.each do |tag|
        if tag["Key"] == "Name"
          fail("VPC name tag value=#{tag["Value"]} does not match name=#{resource[:name]}.") unless tag['Value'] == "#{resource[:name]}_vpc"
        end
        if tag["Key"] == "Environment"
          @property_hash[:environment] = tag["Value"]
        end
      end
    end
    @property_hash[:region] = region
    @property_hash[:cidr] = vpc["CidrBlock"]
    @property_hash[:dns_resolution] = get_dns_resolution(region, @property_hash[:vpcid])
    @property_hash[:dns_hostnames] = get_dns_hostnames(region, @property_hash[:vpcid])
    @property_hash[:state] = vpc["State"]

  end


  def get_dns_resolution(region, vpcid)
    PuppetX::IntechWIFI::Logical.logical(JSON.parse(awscli("ec2", "describe-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--attribute", "enableDnsSupport"))["EnableDnsSupport"]["Value"])
  end

  def set_dns_resolution(region, vpcid, value)
    awscli("ec2", "modify-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--enable-dns-support", "{\"Value\":#{value}}")
  end


  def get_dns_hostnames(region, vpcid)
    PuppetX::IntechWIFI::Logical.logical(JSON.parse(awscli("ec2", "describe-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--attribute", "enableDnsHostnames"))["EnableDnsHostnames"]["Value"])
  end

  def set_dns_hostnames(region, vpcid, value)
    awscli("ec2", "modify-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--enable-dns-hostnames", "{\"Value\":#{value}}")
  end

  def flush
    if @property_flush
      if @property_flush[:dns_hostnames] then set_dns_hostnames(@property_hash[:region], @property_hash[:vpcid], @property_flush[:dns_hostnames]) end
      if @property_flush[:dns_resolution] then set_dns_resolution(@property_hash[:region], @property_hash[:vpcid], @property_flush[:dns_resolution]) end
    end
  end

  ###############################
  #
  #  Property Access
  #
  ###############################

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def dns_hostnames=(value)
    @property_flush[:dns_hostnames] = value
  end

  def dns_resolution=(value)
    @property_flush[:dns_resolution] = value
  end

  def cidr=(value)
    fail("it is not possible to change the CIDR of an active VPC. you will need to delete it and then recreate it again.")
  end

  def region=(value)
    fail("it is not possible to change the region of an active VPC. you will need to delete it and then recreate it again in the new region")
  end

  def vpcid=(value)
    fail("The VPC ID is set by Amazon and cannot be changed.")
  end

end
