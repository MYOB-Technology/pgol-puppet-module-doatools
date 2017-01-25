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

Puppet::Type.type(:iam_policy).provide(:awscli) do
  commands :awscli => "aws"

  def create
    statement = {:Version => "2012-10-17", :Statement => resource[:policy]}
    awscli("iam", "create-policy", "--policy-name", resource[:name], "--policy-document", statement.to_json)
  end

  def destroy
    JSON.parse(awscli('iam', 'list-policy-versions', "--policy-arn", @arn))["Versions"].select{|v|
      !v["IsDefaultVersion"]
    }.each {|v|
      awscli('iam', 'delete-policy-version', "--policy-arn", @arn, '--version-id', v["VersionId"])
    }
    awscli('iam', 'delete-policy', "--policy-arn", @arn)
  end

  def exists?
    debug("searching for iam_policy=#{resource[:name]}\n")

    search = PuppetX::IntechWIFI::AwsCmds.find_iam_profile_by_name(resource[:name], "Local"){ | *arg | awscli(*arg) }

    @arn = search["Arn"]

    policy = PuppetX::IntechWIFI::AwsCmds.find_iam_profile_policy(@arn){ | *arg | awscli(*arg) }
    @property_hash[:policy] = policy["Document"]["Statement"]

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def set_new_policy policy
    v = JSON.parse(awscli('iam', 'list-policy-versions', "--policy-arn", @arn))["Versions"].sort{ | a, b|
      version(a) <=> version(b)
    }
    awscli('iam', 'delete-policy-version', "--policy-arn", @arn, '--version-id', v[0]["VersionId"])  if v.length > 4

    statement = {:Version => "2012-10-17", :Statement => policy}

    awscli("iam", "create-policy-version", "--policy-arn", @arn, "--policy-document", statement.to_json, "--set-as-default")

  end

  def version v
    s = v["VersionId"]
    Integer(s.slice(-s.size + 1))
  end

  def flush
    if !@property_flush.nil? and @property_flush.length > 0
      set_new_policy @property_flush[:policy] if @property_flush[:policy]
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def policy=(value)
    @property_flush[:policy] = value
  end


end