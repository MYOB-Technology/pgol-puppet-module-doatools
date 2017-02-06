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

Puppet::Type.type(:load_balancer).provide(:awscli) do
  commands :awscli => "aws"

  def create
    args = [
        'elbv2', 'create-load-balancer',
        '--region', @resource[:region],
        '--name', @resource[:name],
        '--subnets', 'subnet-a6f08a8b', 'subnet-66d4a43d'
        #'--subnet-ids', resource[:subnets].map{|subnet| PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@resource[:region], 'subnet', subnet){|*arg| awscli(*arg)} }
    ]

    awscli(args.flatten)

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]
    @property_hash[:subnets] = @resource[:subnets]

  end

  def destroy
    args = [
        'elbv2', 'delete-load-balancer',
        '--region', @resource[:region],
        '--load-balancer-arn', @arn
    ]

    awscli(args.flatten)

  end

  def exists?
    #
    #  If the puppet manifest is delcaring the existance of a VPC then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    debug("searching regions=#{regions} for load_balancer=#{resource[:name]}\n")


    search_results = PuppetX::IntechWIFI::AwsCmds.find_load_balancer_by_name(regions, resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:region] = search_results[:region]
    @property_hash[:name] = resource[:name]

    data = search_results[:data][0]
    @arn = data["LoadBalancerArn"]

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0

    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

end