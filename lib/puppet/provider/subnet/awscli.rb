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

    print("region=#{resource[:region]}\n")

    subnet = JSON.parse(awscli('ec2', 'create-subnet', '--region', resource[:region], '--availability-zone', PuppetX::IntechWIFI::Constants.AvailabilityZone(resource[:region], resource[:availability_zone]), '--vpc-id', @property_hash[:vpcid], '--cidr-block', resource[:cidr]))
    @property_hash[:subnetid] = subnet["Subnet"]["SubnetId"]
    @property_hash[:region] = resource[:region]
    @property_hash[:cidr] = subnet["Subnet"]["CidrBlock"]
    @property_hash[:availability_zone] = resource[:availability_zone]

    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:subnetid], '--tags', "Key=Name,Value=#{resource[:name]}")

    @property_hash[:tags] = resource[:tags].nil? ? {} : resource[:tags]
    PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:subnetid], {}, @property_hash[:tags]){| *arg | awscli(*arg)}

    if resource[:public_ip] then
      @property_hash[:public_ip] = PuppetX::IntechWIFI::Logical.logical(resource[:public_ip])
      set_public_ip(@property_hash[:public_ip])
    end

    set_route_table(resource[:route_table]) if !resource[:route_table].nil?

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
    @property_hash[:tags] = PuppetX::IntechWIFI::Tags_Property.parse_tags(data["Tags"])
    @property_hash[:region] = region
    @property_hash[:cidr] = data["CidrBlock"]
    @property_hash[:vpcid] = data["VpcId"]
    @property_hash[:availability_zone] = PuppetX::IntechWIFI::Constants.ZoneName data["AvailabilityZone"]
    @property_hash[:public_ip] = PuppetX::IntechWIFI::Logical.logical(data["MapPublicIpOnLaunch"])

    @property_hash[:vpc] = PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(region, "vpc", @property_hash[:vpcid]) do | *arg |
      awscli(*arg)
    end

    route_table_args = [
        'ec2', 'describe-route-tables', '--region', region,
        '--filter', "Name=association.subnet-id,Values=#{@property_hash[:subnetid]}"
    ]

    rts = JSON.parse(awscli(route_table_args))["RouteTables"]

    if rts.length > 0
      @property_hash[:route_table] = PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(region, "route-table", rts[0]["RouteTableId"]) { |*arg| awscli(*arg) }
    end

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    raise PuppetX::IntechWIFI::Exceptions::VpcNotNamedError , @property_hash[:vpcid]

  end

  def set_public_ip(value)
    awscli('ec2', 'modify-subnet-attribute', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid], '--map-public-ip-on-launch') if PuppetX::IntechWIFI::Logical.logical_true(value)
    awscli('ec2', 'modify-subnet-attribute', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid], '--no-map-public-ip-on-launch') if PuppetX::IntechWIFI::Logical.logical_false(value)
  end

  def set_route_table(value)
    if !@property_hash[:route_table].nil?
      args = [
          'ec2', 'describe-route-tables', '--region', @property_hash[:region],
          '--filters', "Name=association.subnet-id,Values=#{@property_hash[:subnetid]}"
      ]
      rts = JSON.parse(awscli(args))["RouteTables"]
      if rts.length > 0
        rta = rts[0]["Associations"].select{|x| x["SubnetId"] == @property_hash[:subnetid]}.map{|x| x["RouteTableAssociationId"]}
        awscli('ec2', 'disassociate-route-table', '--region', @property_hash[:region], '--association-id', rta)
      end

    end


    awscli('ec2', 'associate-route-table', '--region', @property_hash[:region], '--subnet-id', @property_hash[:subnetid], '--route-table-id',
           PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], "route-table", value) { |*args| awscli(*args)}
    )
  end


  def flush
    if @property_flush
      if @property_flush[:public_ip] then set_public_ip(@property_flush[:public_ip]) end
      if @property_flush[:route_table] then set_route_table(@property_flush[:route_table]) end
      PuppetX::IntechWIFI::Tags_Property.update_tags(@property_hash[:region], @property_hash[:subnetid], @property_hash[:tags], @property_flush[:tags]){| *arg | awscli(*arg)} if !@property_flush[:tags].nil?
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

  def route_table=(value)
    @property_flush[:route_table] = value
  end

  def tags=(value)
    @property_flush[:tags] = value
  end


end
