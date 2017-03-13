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

Puppet::Type.type(:egress_only_internet_gateway).provide(:awscli) do
  commands :awscli => "aws"

  def create

  end

  def destroy

  end

  def exists?
    #
    # At this point in time, it is not possible to tag egress only
    # internet gateways with a name, so the only way we can deal with this, is
    # to find the VPC and then see if an egress only internet gateway is
    # attached to this VPC
    #

    @property_hash[:vpcid] = PuppetX::IntechWIFI::AwsCmds.AwsCmds.find_id_by_name(resource[:region], "vpc", resource[:name]) {| *arg | awscli(*arg) }
    @property_hash[:region] = resource[:region]

    eoigs = JSON.parse(awscli('ec2', 'describe-egress-only-internet-gateways', '--region', search_result[:region]))["EgressOnlyInternetGateways"].select{
        |x| x["Attachments"]["VpcId"] == @property_hash[:vpcid]
    }

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if eoigs.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, resource[:name] if eoigs.length > 1

    eoig = eoigs[0]

    @property_hash[:name] = region[:name]


  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def flush

  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods


end

