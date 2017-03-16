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

Puppet::Type.type(:route_table).provide(:awscli) do
  commands :awscli => "aws"

  def create
    begin
      vpcid = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], "vpc", resource[:vpc]) { | *arg | awscli(*arg) }

    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      fail("We cannot create this route table, unless the vpc=>#{resource[:vpc]} already exists.")
    end

    args = [
        'ec2', 'create-route-table',
        '--region', @resource[:region],
        '--vpc-id', vpcid,
    ]

    rt = JSON.parse(awscli(args))["RouteTable"]
    @property_hash[:rtid] = rt["RouteTableId"]
    @property_hash[:region] = resource[:region]

    awscli('ec2', 'create-tags', '--region', resource[:region], '--resources', @property_hash[:rtid], '--tags', "Key=Name,Value=#{resource[:name]}", "Key=Environment,Value=#{resource[:environment]}")

    #  Create the routes
    resource[:routes].each{|x| create_route(x)}

  end

  def destroy
    args = [
        'ec2', 'delete-route-table',
        '--region', @property_hash[:region],
        '--route-table-id', @property_hash[:rtid],
    ]

    awscli(args)

  end

  def exists?
    search_result = PuppetX::IntechWIFI::AwsCmds.find_tag([@resource[:region]], 'route-table', "Name", "value" ,resource[:name]) { | *arg |  awscli(*arg) }
    @property_hash[:ensure] = :present
    @property_hash[:rtid] = search_result[:tag]["ResourceId"]
    @property_hash[:region] = search_result[:region]
    @property_hash[:name] = resource[:name]

    details_args = [
        'ec2', 'describe-route-tables',
        '--region', @property_hash[:region],
        '--route-table-ids', @property_hash[:rtid]
    ]

    rts = JSON.parse(awscli(details_args))["RouteTables"]

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if rts.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, resource[:name] if rts.length > 1

    rt = rts[0]

    @property_hash[:vpc]= PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], "vpc", rt["VpcId"]){ | *arg | awscli(*arg) }
    @property_hash[:vpc_default] = rt["Associations"].select{|x| x["Main"] == true}.map{|x| x["Main"]}.reduce(PuppetX::IntechWIFI::Logical.logical(false)){ |memo, value| PuppetX::IntechWIFI::Logical.logical_true(memo) ? memo : PuppetX::IntechWIFI::Logical.logical(value)}
    @property_hash[:subnets] = rt["Associations"].select{|x| !x["SubnetId"].nil?}.map do |x|
      PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], "subnet", x["SubnetId"]){ | *arg | awscli(*arg) }
    end
    @property_hash[:environment] = PuppetX::IntechWIFI::AwsCmds.find_tag_from_list(rt["Tags"], "Environment")

    @property_hash[:routes] = rt["Routes"].select{ |x|
      x["GatewayId"] != 'local'
    }.select{ |x|
      x["GatewayId"][0..3] != 'vpce'
    }.map{|x| self.puppetise_route(x)}

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def update_routes current, desired
    add = desired.select{|x| !current.include? x}
    del = current.select{|x| !desired.include? x }

    del.each{|x| delete_route x}
    add.each{|x| create_route x}
  end


  def create_route route
    rt_segments = route.split('|')

    raise RouteFormatError route if rt_segments.length != 3

    args = [
        'ec2', 'create-route',
        '--region', @property_hash[:region],
        '--route-table-id', @property_hash[:rtid],
        '--destination-cidr-block', rt_segments[0],
        self.target_type_args(rt_segments[1], rt_segments[2])
    ]

    awscli(args.flatten)

  end

  def delete_route route
    rt_segments = route.split('|')
    raise RouteFormatError route if rt_segments.length != 3

    args = [
        'ec2', 'delete-route',
        '--region', @property_hash[:region],
        '--route-table-id', @property_hash[:rtid],
        '--destination-cidr-block', rt_segments[0],
    ]

    awscli(args.flatten)

  end

  def puppetise_route route
    #
    #  format:  cidr|target type|target name/id
    #
    #

    handler = [
        [ 'GatewayId', self.method(:igw_id_to_name), 'igw'],
        [ 'NatGatewayId', self.method(:natgw_id_to_name), 'nat'],
    ].select{|x| !route[x[0]].nil?}.map{|x| [route[x[0]], x[1], x[2]]}.flatten

    name = handler[1].(handler[0])

    "#{route['DestinationCidrBlock']}|#{handler[2]}|#{name}"

  end

  def target_type_args spec, ident
    data = {
        'igw' => [ '--gateway-id', self.method(:igw_name_to_id)],
        'nat' => [ '--nat-gateway-id', self.method(:natgw_name_to_id)]
    }[spec]

    [data[0], data[1].(ident)]
  end

  def flush
    if @property_flush
      update_routes(@property_hash[:routes], @property_flush[:routes]) if !@property_flush[:routes].nil?
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def routes=(value)
    @property_flush[:routes] = value
  end

  #
  # Methods to convert between target names and ids.
  #
  # Because not all target types can be tagged, there is no global way
  # to convert between identity and puppet object name
  #

  def igw_id_to_name(id)
    PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], 'internet-gateway', id) { | *arg |  awscli(*arg) }
  end

  def natgw_id_to_name(id)
    # We need to identify the natgw subnet, and then find the subnets name.

    cli_args = [
        'ec2', 'describe-nat-gateways', '--region', @property_hash[:region], '--nat-gateway-ids', id
    ]

    nat = JSON.parse(awscli(cli_args.flatten))["NatGateways"][0]

    PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'subnet', nat["SubnetId"]) { | *arg |  awscli(*arg) }

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    id
  end


  def igw_name_to_id(name)
    PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'internet-gateway', name) { | *arg |  awscli(*arg) }
  end

  def natgw_name_to_id(name)
    snid = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'subnet', name) { | *arg |  awscli(*arg) }

    cli_args = [
        'ec2', 'describe-nat-gateways', '--region', @property_hash[:region], '--filter', "Name=subnet-id,Values=#{snid}"
    ]
    nats = JSON.parse(awscli(cli_args))["NatGateways"].select do |x|
      x["SubnetId"] == snid and !["failed", "deleted", "deleting"].include? x["State"]
    end

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if nats.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, resource[:name] if nats.length > 1

    # Now we can be sure we have exactly one NAT gateway.
    nats[0]["NatGatewayId"]

  end


end
