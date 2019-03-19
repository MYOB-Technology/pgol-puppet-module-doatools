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
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/autoscaling_rules'

module PuppetX
  module IntechWIFI
    module AwsCmds
      @vpc_tag_cache = { :key => nil, :value => nil}

      def AwsCmds.find_tag_from_list(tag_list, name)
        tags = tag_list.select{|x| x["Key"] == name}.map{|x| x["Value"]}
        tags.length == 1 ? tags[0] : nil
      end

      def AwsCmds.clear_vpc_tag_cache(name)
        @vpc_tag_cache = { :key => nil, :value => nil} if @vpc_tag_cache[:key] == name
      end

      def AwsCmds.find_vpc_tag(regions, name, &aws_command)
        #  Typically, a puppet run will only be dealing with the one VPC, but many components
        #  will need to obtain the vpcid from vpc name.  As an optimisation, we cache the last answer.
        #

        result = nil

        result = @vpc_tag_cache[:value] unless @vpc_tag_cache[:key] != name

        if result == nil
          result = AwsCmds.find_tag(regions, "vpc", "Name", "value", name, &aws_command)
          @vpc_tag_cache = { :key => name, :value => result}
        end
        result
      end

      def AwsCmds.find_name_or_id_by_id(region, resource_type, id, &aws_command)
        AwsCmds.find_tag([region], resource_type, "Name", "resource-id", id, &aws_command)[:tag]["Value"]
      rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
        id
      end


      def AwsCmds.find_name_by_id(region, resource_type, id, &aws_command)
        AwsCmds.find_tag([region], resource_type, "Name", "resource-id", id, &aws_command)[:tag]["Value"]
      end

      def AwsCmds.find_id_by_name(region, resource_type, id, &aws_command)
        AwsCmds.find_tag([region], resource_type, "Name", "value", id, &aws_command)[:tag]["ResourceId"]
      end


      def AwsCmds.find_tag(regions, resource_type, key, filter, value, &aws_command)
        tags = []
        region = nil
        regions.each{ |r|
          output = aws_command.call('ec2', 'describe-tags', '--filters', "Name=resource-type,Values=#{resource_type}", "Name=key,Values=#{key}", "Name=#{filter},Values=#{value}", '--region', r)
          JSON.parse(output)["Tags"].each{|t| tags << t; region = r }
        }

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, value if tags.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, value if tags.length > 1

        {:tag => tags[0], :region => region }
      end

      def AwsCmds.find_launch_configuration_by_name( regions, name, &aws_command)
        lcs = []
        region = nil
        regions.each{ |r|
          output = JSON.parse(aws_command.call('autoscaling', 'describe-launch-configurations', '--region', r))
          lcs << output["LaunchConfigurations"].select{|l| PuppetX::IntechWIFI::Autoscaling_Rules.is_valid_lc_name?(name, l['LaunchConfigurationName'] )}.reduce([]){|memo, lc| memo << lc }
        }
        result = lcs.flatten
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if lcs.length > 1  #  matches in more than one region.

        result.max { |a, b| a["LaunchConfigurationName"]  <=> b["LaunchConfigurationName"]}
      end

      def AwsCmds.find_autoscaling_by_name( regions, name, aws_command = Proc.new)
        result = regions.map{ |r|
          { :region => r, :data => JSON.parse(aws_command.call('autoscaling', 'describe-auto-scaling-groups', '--region', r, "--auto-scaling-group-names", name))["AutoScalingGroups"]}
        }.select{ |a| a[:data].length != 0 }.flatten

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  matches in more than one region.
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result[0][:data].length > 1  #  More than one match in the region.

        {
            :region => result[0][:region],
            :data   => result[0][:data][0],
        }
      end

      def AwsCmds.find_lifecyle_hooks_by_asg_name(regions, name, aws_command = Proc.new)
        find_autoscaling_by_name(regions, name, aws_command) #check if the autoscaling group exists first
        result = regions.map{ |r|
          { :region => r, :data => JSON.parse(aws_command.call('autoscaling', 'describe-lifecycle-hooks', '--region', r, '--auto-scaling-group-name', name))['LifecycleHooks'] }
        }

        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  matches in more than one region.

        {
            :region => result[0][:region],
            :data   => result[0][:data],
        }
      end

      def AwsCmds.find_iam_instance_profile_by_name(name, &aws_command)
        JSON.parse(aws_command.call('iam', 'get-instance-profile', "--instance-profile-name", name))["InstanceProfile"]
      rescue Puppet::ExecutionFailure => e
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name
      end

      def AwsCmds.find_iam_profile_by_name(name, scope, &aws_command)
        result = JSON.parse(aws_command.call('iam', 'list-policies', "--scope", scope))["Policies"].select{|p| p["PolicyName"] == name}

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches

        result[0]
      end

      def AwsCmds.find_elb_target_by_name(name, region, &aws_command)
        args = [
            'elbv2', 'describe-target-groups',
            '--region', region,
            '--names', name
        ]
        JSON.parse(aws_command.call(args.flatten))["TargetGroups"][0]["TargetGroupArn"]

      rescue Puppet::ExecutionFailure => e
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name
      end



      def AwsCmds.find_iam_profile_policy(arn, &aws_command)
        version_id = JSON.parse(aws_command.call('iam', 'list-policy-versions', "--policy-arn", arn))["Versions"].select{|p|
          p["IsDefaultVersion"]
        }.map{|p| p["VersionId"] }

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, arn if version_id.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, arn if version_id.length > 1  #  Multiple matches

        JSON.parse(aws_command.call('iam', 'get-policy-version', "--policy-arn", arn, "--version-id", version_id[0]))["PolicyVersion"]
      end

      def AwsCmds.find_iam_role_by_name(name, &aws_command)
        result = JSON.parse(aws_command.call('iam', 'list-roles'))["Roles"].select{|p| p["RoleName"] == name}

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches

        result[0]
      end

      def AwsCmds.find_iam_role_by_arn(arn,  &aws_command)
        result = JSON.parse(aws_command.call('iam', 'list-roles'))["Roles"].select{|p| p["Arn"] == arn}
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches

        result[0]
      end

      def AwsCmds.find_rds_by_name(regions, name, &aws_command)
        result = regions.map{ |r|
          {
              :region => r,
              :data => JSON.parse(aws_command.call('rds', 'describe-db-instances', '--region', r))["DBInstances"].select{ |db|
                db["DBInstanceIdentifier"] == name
              }
          }
        }.select{ |a| a[:data].length != 0}.flatten



        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result[0][:data].length > 1  #  More than one match in the region.

        result[0]
      end

      def AwsCmds.find_rds_subnet_group_by_name(regions, name, &aws_command)
        result = regions.map{ |r|
          {
              :region => r,
              :data => JSON.parse(aws_command.call('rds', 'describe-db-subnet-groups', '--region', r, '--db-subnet-group-name', name))["DBSubnetGroups"]
          }
        }.select{ |a| a[:data].length != 0}.flatten

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result[0][:data].length > 1  #  More than one match in the region.

        result[0]

      rescue Puppet::ExecutionFailure => e
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name
      end

      def AwsCmds.find_load_balancer_by_name(regions, name, &aws_command)
        result = regions.map{ |r|
          {
              :region => r,
              :data => JSON.parse(aws_command.call('elbv2', 'describe-load-balancers', '--region', r, '--names', name))["LoadBalancers"]
          }
        }.select{ |a| a[:data].length != 0}.flatten

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result[0][:data].length > 1  #  More than one match in the region.

        result[0]

      rescue Puppet::ExecutionFailure => e
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name
      end

      def AwsCmds.find_deployment_group_by_name(regions, application_name, name, &aws_command)
        result = regions.map{ |r|
          {
              :region => r,
              :data => JSON.parse(
                aws_command.call('deploy', 'list-deployment-groups', '--region', r, '--application-name', application_name)
              )["deploymentGroups"].select{ | g | g == name }
          }
        }.select{ |a| a[:data].length != 0}.flatten

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result.length > 1  #  Multiple matches
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result[0][:data].length > 1  #  More than one match in the region.

        details = JSON.parse(aws_command.call(
            'deploy', 'get-deployment-group',
            '--region', result[0][:region],
            '--application-name', application_name,
            '--deployment-group-name', result[0][:data]))

        {
          :region => result[0][:region],
          :data => details
        }
      end

      def AwsCmds.find_lambda_by_name(region, name, &aws_command)
        functions = JSON.parse(aws_command.call('lambda', 'list-functions', '--region', region))['Functions']

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if functions.empty?
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if functions.select { |function| function['FunctionName'] == name }.empty?

        JSON.parse(aws_command.call('lambda', 'get-function', '--function-name', name, '--region', region))
      end

      def AwsCmds.find_sns_by_name(region, name, &aws_command)
        topics = JSON.parse(aws_command.call('sns', 'list-topics', '--region', region))['Topics']

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if topics.empty?
        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if topics.select { |topic| topic['TopicArn'].end_with? name }.empty?

        arn = topics.select { |topic| topic['TopicArn'].end_with? name }.first['TopicArn']

        JSON.parse(aws_command.call('sns', 'get-topic-attributes', '--topic-arn', arn, '--region', region))['Attributes']
      end
    end
  end
end
