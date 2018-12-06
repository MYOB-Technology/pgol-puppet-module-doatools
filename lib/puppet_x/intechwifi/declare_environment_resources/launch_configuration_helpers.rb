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

require 'puppet_x/intechwifi/declare_environment_resources/service_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/role_helpers'
require 'puppet_x/intechwifi/declare_environment_resources'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module LaunchConfigurationHelpers
        OPTIONAL_PARAMS = ['ssh_key_name', 'userdata']

        def self.get_role_based_launch_configuration(name, services, roles, zones, sg_label_format, scratch)
          roles.map { |role, role_details| get_launch_configuration(name, role, role_details, zones, role_details['zone'], scratch)
            .merge({ 'security_groups' => get_role_based_security_groups(name, role, sg_label_format) })
            .merge(optional_parameters(role_details))
          }
        end

        def self.get_service_based_launch_configuration(name, services, roles, zones, sg_label_format, scratch)
          roles.map { |role, role_details| get_launch_configuration(name, role, role_details, zones, role_details['zone'], scratch)
            .merge({ 'security_groups' => get_service_based_security_groups(name, services, roles, role_details, sg_label_format) })
            .merge(optional_parameters(role_details))
          }
        end

        def self.get_launch_configuration(name, role, role_details, zones, zone, scratch)
          {
            'name' => AutoScalerHelper.GenerateLaunchConfigName(name, role, zones, zone, scratch),
            'image' => role_details['ec2']['image'],
            'instance_type' => role_details['ec2']['instance_type'],
            'iam_instance_profile' => IAMHelper.GenerateInstanceProfileName(name, role, scratch),
            'public_ip' => role_details['zone'] == 'public' ? :enabled : :disabled
          }
        end

        def self.optional_parameters(role_details)
          role_details.select { |param, _value| OPTIONAL_PARAMS.include?(param) }
        end
        
        def self.get_role_based_security_groups(name, role, sg_label_format)
          RoleHelpers.calculate_security_group_name(name, role, sg_label_format)
        end

        def self.get_service_based_security_groups(name, services, roles, role_details, sg_label_format)
          ServiceHelpers.services(role_details).map{ |service|
                         ServiceHelpers.calculate_security_group_name(name, service, sg_label_format)
                       }.select{ |sg|
                         ServiceHelpers.calculate_security_groups(name, roles, services, sg_label_format).map{ |sg| sg['name'] }.include?(sg)
                       }
        end
      end
    end
  end
end

