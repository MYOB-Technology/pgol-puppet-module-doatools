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

    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:vpcid], '--tags', "Key=Name,Value=#{resource[:name]}")
    if resource[:dns_hostnames] then @property_flush[:dns_hostnames] = resource[:dns_hostnames] end
    if resource[:dns_resolution] then @property_flush[:dns_resolution] = resource[:dns_resolution] end

    route_id = JSON.parse(awscli('ec2', 'describe-route-tables', '--region', resource[:region], '--filter', "Name=vpc-id,Values=#{@property_hash[:vpcid]}"))["RouteTables"][0]["RouteTableId"]
    info("vpc #{resource[:name]} has a default route table #{route_id}")
    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', route_id, '--tags', "Key=Name,Value=#{resource[:name]}")

    sg_id = JSON.parse(awscli('ec2', 'describe-security-groups', '--region', resource[:region], '--filter', "Name=vpc-id,Values=#{@property_hash[:vpcid]}", "Name=group-name,Values=default"))["SecurityGroups"][0]["GroupId"]
    info("vpc #{resource[:name]} has a default security group #{sg_id}")
    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', sg_id, '--tags', "Key=Name,Value=#{resource[:name]}")

    @property_hash[:tags] = resource[:tags]
    PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:vpcid], {}, @property_hash[:tags]){| *arg | awscli(*arg)} if !@property_hash[:tags].nil?

    @property_hash[:ensure] = :present

  end

  def destroy
    route_id = JSON.parse(awscli('ec2', 'describe-route-tables', '--region', resource[:region], '--filter', "Name=vpc-id,Values=#{@property_hash[:vpcid]}"))["RouteTables"][0]["RouteTableId"]
    info("vpc #{resource[:name]} has a default route table #{route_id}")
    awscli('ec2', 'delete-tags', '--region', resource[:region], '--resources', route_id)

    response = awscli('ec2', 'delete-vpc', '--region', @property_hash[:region], '--vpc-id', @property_hash[:vpcid])
    debug("Clearing vpc-id cache for #{name}\n")
    PuppetX::IntechWIFI::AwsCmds.clear_vpc_tag_cache @property_hash[:name]
    @property_hash.clear
  end

  def exists?

    result = false

    if %i[name region tags cidr dns_resolution dns_hostnames].all? {|s| @property_hash.key? s}
      return true
    end
    
    if @property_hash[:region]
      #  If the vpc has already been fetched, the region has already been defined in the property hash 
      regions = [ @property_hash[:region] ]
    elsif resource[:region]
      #  If the puppet manifest is delcaring the existance of a VPC then we know its region.
      regions = [ resource[:region] ] 
    else 
      #  If we don't know the region, then we have to search each region in turn.
      regions = PuppetX::IntechWIFI::Constants.Regions
    end
      
    debug("searching regions=#{regions} for vpc=#{resource[:name]}\n")

    begin
      vpcs_properties_list = []
      if regions.length > 1
        notice("No REGION environmental variable set - searching vpc instances across all available regions")
        # Running queries for each region in its own thread as an optimization
        threads = []
        debug("searching regions=#{regions} for vpc with \n")
        regions.each do |r|
          threads << Thread.new { Thread.current[:output] = PuppetX::IntechWIFI::AwsCmds.find_vpc_properties_by_name(r, resource[:name]){| *arg | awscli(*arg)}}
        end

        threads.each do |t|
          t.join
          vpcs_properties_list << t[:output]
        end

      else
        vpcs_properties_list << PuppetX::IntechWIFI::AwsCmds.find_vpc_properties_by_name(regions[0], resource[:name ]){| *arg | awscli(*arg)}
      end

      if vpcs_properties_list.length == 0
        return false
      end

    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      debug(e)
      return false
    end

    vpc_properties = vpcs_properties_list[0]

    @property_hash[:name] = resource[:name]
    @property_hash[:ensure] = :present
    @property_hash[:vpcid] = vpc_properties[:vpcid]
    @property_hash[:region] = vpc_properties[:region]
    @property_hash[:tags] = vpc_properties[:tags]
    @property_hash[:cidr] = vpc_properties[:cidr]
    @property_hash[:dns_hostnames] = vpc_properties[:dns_hostnames]
    @property_hash[:dns_resolution] = vpc_properties[:dns_resolution]
    @property_hash[:state] = vpc_properties[:state]

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false
  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def self.instances
    regions = PuppetX::IntechWIFI::Constants.Regions 
    if regions.length > 1
      notice("No REGION environmental variable set - retrieving vpc instances across all available regions")
      # Running queries for each region in its own thread as an optimization
      threads = []
      vpcs = []

      debug("searching regions=#{regions} for vpcs\n")
      regions.each do |r|
        threads << Thread.new { Thread.current[:output] = self.fetch_vpcs(r) }
      end

      threads.each do |t|
        t.join
        vpcs.concat t[:output]
      end

    else
      vpcs = fetch_vpcs(regions[0])
    end
    return vpcs
  end

  def self.fetch_vpcs(region)
    vpc_properties_list = PuppetX::IntechWIFI::AwsCmds.find_all_vpc_properties(region){| *arg | awscli(*arg)}

    vpcs = []
    vpc_properties_list.each{ |vpc_properties|
      vpc = new(vpc_properties)
      vpcs << vpc
    }

    return vpcs
  end

  def get_dns_resolution(region, vpcid)
    if @property_hash[:dns_resolution].nil?
      return PuppetX::IntechWIFI::AwsCmds.get_vpc_dns_resolution(region, vpcid){| *arg | awscli(*arg)}
    else
      return @property_hash[:dns_resolution]
    end
  end

  def set_dns_resolution(region, vpcid, value)
    awscli("ec2", "modify-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--enable-dns-support", "{\"Value\":#{PuppetX::IntechWIFI::Logical.string_true_or_false(value)}}")
  end


  def get_dns_hostnames(region, vpcid)
    if @property_hash[:dns_hostnames].nil?
      return PuppetX::IntechWIFI::AwsCmds.get_vpc_dns_hostname(region, vpcid){| *arg | awscli(*arg)}
    else
      return @property_hash[:dns_hostnames]
    end
  end

  def set_dns_hostnames(region, vpcid, value)
    awscli("ec2", "modify-vpc-attribute", "--vpc-id", "#{vpcid}", "--region", "#{region}", "--enable-dns-hostnames", "{\"Value\":#{PuppetX::IntechWIFI::Logical.string_true_or_false(value)}}")
  end

  def flush
    if @property_flush

      if @property_flush[:dns_hostnames] then set_dns_hostnames(@property_hash[:region], @property_hash[:vpcid], @property_flush[:dns_hostnames]) end
      if @property_flush[:dns_resolution] then set_dns_resolution(@property_hash[:region], @property_hash[:vpcid], @property_flush[:dns_resolution]) end
      
      # Hack to fix Name tag always causing update and being overwritten
      if !@property_flush[:tags].nil? and ! (@property_flush[:tags].key? "Name" or @property_flush[:tags].key? "name" )
        @property_flush[:tags]["Name"] = @property_hash[:name]
      end

      PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:vpcid], @property_hash[:tags], @property_flush[:tags]){| *arg | awscli(*arg)} if !@property_flush[:tags].nil?
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

  def tags=(value)

    @property_flush[:tags] = value
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
