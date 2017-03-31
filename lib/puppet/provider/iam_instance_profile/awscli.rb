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

Puppet::Type.type(:iam_instance_profile).provide(:awscli) do
  commands :awscli => "aws"

  def create

    args = [
        'iam', 'create-instance-profile',
        '--instance-profile-name', resource[:name],
    ]

    @property_hash[:arn] = JSON.parse(awscli(args))["InstanceProfile"]["Arn"]
    @property_hash[:name] = resource[:name]

    set_iam_role(resource[:iam_role])

  end

  def destroy

    iip = PuppetX::IntechWIFI::AwsCmds.find_iam_instance_profile_by_name(@property_hash[:name]){ | *arg | awscli(*arg) }
    iip["Roles"].each do |role|
      detach_args = [
          'iam', 'remove-role-from-instance-profile',
          '--instance-profile-name', @property_hash[:name],
          '--role-name', @property_hash[:iam_role]
      ]
      awscli(detach_args)
    end

    args = [
        'iam', 'delete-instance-profile',
        '--instance-profile-name', resource[:name],
    ]

    awscli(args)
  end

  def exists?

    iip = PuppetX::IntechWIFI::AwsCmds.find_iam_instance_profile_by_name(resource[:name]){ | *arg | awscli(*arg) }

    @property_hash[:iam_role] = iip["Roles"][0]["RoleName"] if iip["Roles"].length == 1
    @property_hash[:arn] = iip["Arn"]
    @property_hash[:name] = resource[:name]

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  end

  def flush
    if !@property_flush.nil? and @property_flush.length > 0
      set_iam_role @property_flush[:iam_role] if !@property_flush[:iam_role].nil?
    end
  end

  def set_iam_role(role)
    if !@property_hash[:iam_role].nil?
      detach_args = [
          'iam', 'remove-role-from-instance-profile',
          '--instance-profile-name', @property_hash[:name],
          '--role-name', @property_hash[:iam_role]
      ]
      awscli(detach_args)
    end

    attach_args = [
        'iam', 'add-role-to-instance-profile',
        '--instance-profile-name', @property_hash[:name],
        '--role-name', role
    ]

    awscli(attach_args)
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def iam_role=(value)
    @property_flush[:iam_role] = value
  end

end

