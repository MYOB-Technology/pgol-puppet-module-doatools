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

Puppet::Type.type(:security_group_rules).provide(:awscli) do
  commands :awscli => "aws"

  def create
    fail("The security group #{resource[:name]} must exist first.") if !@property_hash[:sgid]

    apply_network_rules @property_hash[:region], [], @resource[:in], "authorize-security-group-ingress", "revoke-security-group-ingress" if @resource[:in]
    apply_network_rules @property_hash[:region], [], @resource[:out], "authorize-security-group-egress", "revoke-security-group-egress" if @resource[:out]

  end

  def destroy()
    set_in(@property_hash[:region], [])
    set_out(@property_hash[:region], [])
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

    @property_hash[:region] = search_result[:region]
    @property_hash[:sgid] = search_result[:tag]["ResourceId"]

    #  The security_group_rules puppet object exists if its security group exists AND that security group has at least one in / out rule.
    groups = JSON.parse(awscli('ec2', 'describe-security-groups', '--region', search_result[:region], '--group-id', @property_hash[:sgid]))["SecurityGroups"]

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, resource[:name] if groups.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, resource[:name] if groups.length > 1

    ingress = PuppetX::IntechWIFI::Network_Rules.AwsToPuppetString(groups[0]["IpPermissions"], search_result[:region]) { | *arg | awscli(*arg) }
    egress = PuppetX::IntechWIFI::Network_Rules.AwsToPuppetString(groups[0]["IpPermissionsEgress"], search_result[:region]) { | *arg | awscli(*arg) }

    @property_hash[:in] = ingress
    @property_hash[:out] = egress
    true


  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def extract_values(region, data)
    @property_hash[:in] = PuppetX::IntechWIFI::Network_Rules.AwsToPuppetString(data["IpPermissions"], region) do | *arg |
      awscli(*arg)
    end
    @property_hash[:out] = PuppetX::IntechWIFI::Network_Rules.AwsToPuppetString(data["IpPermissionsEgress"], region) do | *arg |
      awscli(*arg)
    end
  end


  def set_in(region, data)
    apply_network_rules region, @property_hash[:in], data, "authorize-security-group-ingress", "revoke-security-group-ingress"
  end

  def set_out(region, data)
    apply_network_rules region, @property_hash[:out], data, "authorize-security-group-egress", "revoke-security-group-egress"
  end

  def apply_network_rules region, current, planned, add, remove
    add_rules = planned.select{|r| !current.include? r }
    delete_rules = current.select{|r| !planned.include? r }

    add_rules.map{|a|
      data = a.split("|")

      args = [ "ec2", add, "--region", region, "--group-id", @property_hash[:sgid], "--protocol", data[0] ]
      args << ["--port", data[1]] if data[1] and data[1].length > 0
      args << ["--cidr", data[3]] if data[2] == "cidr"

      if data[2] == "sg"
        name = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(region, 'security-group', data[3]) do | *arg |
          awscli(*arg)
        end

        args << ["--source-group", name]
      end

      awscli(args.flatten)

    }
    delete_rules.each{|d|
      data = d.split("|")

      args = [ "ec2", remove, "--region", region, "--group-id", @property_hash[:sgid], "--protocol", data[0] ]
      args << ["--port", data[1]] if data[1] and data[1].length > 0
      args << ["--cidr", data[3]] if data[2] == "cidr"
      if data[2] == "sg"
        name = PuppetX::IntechWIFI::AwsCmds.find_id_by_name(region, 'security-group', data[3]) do | *arg |
          awscli(*arg)
        end

        args << ["--source-group", name]
      end
      awscli(args.flatten)
    }
  end



  def flush
    if @property_flush
      if @property_flush[:in] then set_in(@property_hash[:region], @property_flush[:in]) end
      if @property_flush[:out] then set_out(@property_hash[:region], @property_flush[:out]) end
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def in=(value)
    @property_flush[:in] = value
  end

  def out=(value)
    @property_flush[:out] = value
  end

end
