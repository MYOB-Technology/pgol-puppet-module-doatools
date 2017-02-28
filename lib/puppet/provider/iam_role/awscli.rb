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

Puppet::Type.type(:iam_role).provide(:awscli) do
  commands :awscli => "aws"

  def create
    print "resource[:trust] = #{resource[:trust]}\n"

    statement = generate_role_statement(resource[:trust])
    awscli("iam", "create-role", "--role-name", resource[:name], "--assume-role-policy-document", statement.to_json)

    resource[:policies].map{|p| PuppetX::IntechWIFI::AwsCmds.find_iam_profile_by_name(p, "All"){ | *arg | awscli(*arg) }["Arn"]}.each{|p|
      awscli("iam", 'attach-role-policy', '--role-name', resource[:name],'--policy-arn', p)
    }


  end

  def destroy
    @property_hash[:policies].map{|p| PuppetX::IntechWIFI::AwsCmds.find_iam_profile_by_name(p, "All"){ | *arg | awscli(*arg) }["Arn"] }.each{|p|
      awscli("iam", "detach-role-policy", "--role-name", @property_hash[:name], "--policy-arn", p)
    }

    awscli("iam", "delete-role", "--role-name", @property_hash[:name])

  end


  def exists?
    debug("searching for iam_role=#{resource[:name]}\n")

    search = PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(resource[:name]){ | *arg | awscli(*arg) }

    @property_hash[:name] = resource[:name]

    @property_hash[:trust] = search["AssumeRolePolicyDocument"]["Statement"].select{ |t|
      t["Principal"].has_key? "Service"
    }.map{ |t| PuppetX::IntechWIFI::Constants.PrincipalKey t["Principal"]["Service"]}

    @arn = search["Arn"]

    policies = JSON.parse(awscli('iam', 'list-attached-role-policies', '--role-name', resource[:name]))["AttachedPolicies"]
    @property_hash[:policies] = policies.map{|p| p["PolicyName"] }
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def generate_role_statement(trust)
    trust = ['ec2'] if trust.nil?
    {
        :Version => "2012-10-17",
        :Statement => trust.map{ |k|
          {
              :Action => "sts:AssumeRole",
              :Effect => "Allow",
              :Principal => {
                  :Service => "#{PuppetX::IntechWIFI::Constants.PrincipalValue(k)}"
              }
          }
        }
    }
  end

  def set_trust(new_trust)
    statement = generate_role_statement(new_trust)
    aws("iam", "update-assume-role-policy", @property_hash[:name], "--policy-document", statement.to_json)
  end

  def set_policies(o, n)
    add = n.select{|p| !o.include? p }
    remove = o.select{|p| !n.include? p }

    remove.map{|p| PuppetX::IntechWIFI::AwsCmds.find_iam_profile_by_name(p, "All"){ | *arg | awscli(*arg) }["Arn"] }.each{|p|
      awscli("iam", "detach-role-policy", "--role-name", @property_hash[:name], "--policy-arn", p)
    }
    add.map{|p| PuppetX::IntechWIFI::AwsCmds.find_iam_profile_by_name(p, "All"){ | *arg | awscli(*arg) }["Arn"] }.each{|p|
      awscli("iam", "attach-role-policy", "--role-name", @property_hash[:name], "--policy-arn", p)
    }
  end

  def flush
    if @property_flush
      if @property_flush[:trust] then set_trust(@property_flush[:trust]) end
      if @property_flush[:policies] then set_policies(@property_hash[:policies], @property_flush[:policies]) end
    end
  end


  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def policies=(value)
    @property_flush[:policies] = value
  end

  def trust=(value)
    @property_flush[:trust] = value
  end

end
