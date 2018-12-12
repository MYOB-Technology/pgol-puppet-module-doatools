#  Copyright (C) 2018 MYOB / Michael Shaw
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

Puppet::Type.type(:deployment_group).provide(:awscli) do
  commands :awscli => "aws"

  def create
    args = [
        'deploy', 'create-deployment-group',
        '--region', @resource[:region],
        '--deployment-group-name', @resource[:name],
        '--application-name', @resource[:application_name],
        '--service-role-arn', PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(@resource[:service_role]) { |*arg| awscli(*arg) }['Arn']
    ]

    args << [ '--auto-scaling-groups', @resource[:autoscaling_groups] ] if !@resource[:autoscaling_groups].nil?

    awscli(args.flatten)

  end

  def destroy
    args = [
        'deploy', 'delete-deployment-group',
        '--region', @property_flush[:region],
        '--deployment-group-name', @property_flush[:name],
        '--application-name', @property_flush[:application_name],
    ]

    awscli(args.flatten)
  end

  def checkworks
    puts 'DID I MAKE IT HERE PELASE {P:LEASE'
    true
  end


  def exists?
    #
    #  please have a single region
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    search_results = PuppetX::IntechWIFI::AwsCmds.find_deployment_group_by_name(regions, resource[:application_name], name) do | *arg |
      awscli(*arg)
    end

    serviceRoleArn = search_results[:data]['deploymentGroupInfo']['serviceRoleArn']

    begin
        service_role = PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_arn(serviceRoleArn) do | *arg |
          awscli(*arg)
        end
        @property_hash[:service_role] = service_role["RoleName"]

      rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e

      rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e

    end

    @property_hash[:application_name] = resource[:application_name]
    @property_hash[:region] = resource[:region]
    @property_hash[:autoscaling_groups] = search_results[:data]['deploymentGroupInfo']['autoScalingGroups'].map{|data| data["name"] }

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
        args = [
            'deploy', 'update-deployment-group',
            '--region', @resource[:region],
            '--current-deployment-group-name', @resource[:name],
            '--application-name', @resource[:application_name],
        ]
        args << [ '--service-role-arn', PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(@property_flush[:service_role]) { |*arg|
            awscli(*arg)
        }['Arn'] ] if !@property_flush[:service_role].nil?
        args << [ '--auto-scaling-groups', @property_flush[:autoscaling_groups] ] if !@property_flush[:autoscaling_groups].nil?

        awscli(args.flatten)
    end
  end


  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def application_name=(value)
    @property_flush[:application_name] = value
  end

  def service_role=(value)
    @property_flush[:service_role] = value
  end

  def autoscaling_groups=(value)
    @property_flush[:autoscaling_groups] = value
  end

end
