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

Puppet::Type.type(:nat_gateway).provide(:awscli) do
  commands :awscli => "aws"

  def create
    eip_args = [
        'ec2', 'describe-addresses', '--region', @resource[:region],
        '--filters', 'Name=domain,Values=vpc',
    ]

    eip_args << [ '--public-ips', @resource[:elastic_ip] ] if !@resource[:elastic_ip].nil?

    eips = JSON.parse(awscli(eip_args.flatten))["Addresses"].select{|x| x["AssociationId"].nil?}.map{|x| x["AllocationId"]}

    fail("No available Elastic IP address") if eips.length == 0

    cli_args = [
        'ec2', 'create-nat-gateway', '--region', @resource[:region],
        '--subnet-id', PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], 'subnet', resource[:name]){ | *arg | awscli(*arg) },
        '--allocation-id', eips[0],
    ]

    awscli(cli_args)

  end

  def destroy
    cli_args = [
        'ec2', 'delete-nat-gateway', '--region', @resource[:region],
        '--nat-gateway-id', @property_hash[:ngw_id]
    ]

    awscli(cli_args.flatten)
  end

  def exists?
    # Find the VPC first...
    @property_hash[:region] = resource[:region]
    @property_hash[:subnetid] = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(resource[:region], 'subnet', resource[:name]){ | *arg | awscli(*arg) }

    cli_args = [
        'ec2', 'describe-nat-gateways', '--region', @property_hash[:region], '--filter', "Name=subnet-id,Values=#{@property_hash[:subnetid]}"
    ]
    nats = JSON.parse(awscli(cli_args))["NatGateways"].select do |x|
      x["SubnetId"] == @property_hash[:subnetid] and !["failed", "deleted", "deleting"].include? x["State"]
    end

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if nats.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, resource[:name] if nats.length > 1

    # Now we can be sure we have exactly one NAT gateway.
    nat=nats[0]

    public_ips = nat["NatGatewayAddresses"].select{|x| !x["PublicIp"].nil?}.map{|x| x["PublicIp"]}
    @property_hash[:elastic_ip] = public_ips[0] if public_ips.length == 1
    @property_hash[:ngw_id] = nat["NatGatewayId"]
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def flush

  end

  mk_resource_methods

end


