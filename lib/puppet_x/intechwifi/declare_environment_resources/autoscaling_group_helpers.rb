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

require 'puppet_x/intechwifi/declare_environment_resources/loadbalancer_helper'
require 'puppet_x/intechwifi/declare_environment_resources'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module AutoscalingGroupHelpers
        def self.generate(name, services, roles, zones, status, region, network, scratch)
          resources = roles.map { |role, role_data| {
            generate_auto_scaler_name(name, role, zones, role_data['zone'], scratch) => 
              get_groups(name, status, role, role_data, region, network, zones, scratch)
              .merge(get_scaling_properties(role_data))
              .merge(get_loadbalancers(name, roles, role, services))
          } }
          .reduce({}){|hash, kv| hash.merge(kv)}
          { 'resource_type' => "autoscaling_group", 'resources' => resources }
        end
        
        def self.get_groups(name, status, role, role_data, region, network, zones, scratch)
          {
            'ensure' => status,
            'region' => region,
            'launch_configuration' => generate_launch_configuration_name(name, role, zones, role_data['zone'], scratch),
            'subnets' => get_group_subnets(name, role_data, network, zones, scratch),
            'tags' => { 'Role' => role, 'Name' => "#{role}_#{name}" }
            #TODO: We need to set the internet gateway
            #'internet_gateway' => nil,
            #TODO: We need to set the nat gateway
            #'nat_gateway' => nil,
          }
        end

        def self.get_group_subnets(name, role_data, network, zones, scratch)
          SubnetHelpers.CalculateSubnetData(name, network, zones, scratch)
            .select { |subnet| subnet[:zone] == role_data['zone'] }
            .map { |subnet| subnet[:name] }
        end

        def self.get_scaling_properties(role_data)
          convert_to_autoscale_values(get_default_scaling().merge(copy_scaling_values(role_data.key?('scaling') ? role_data['scaling'] : {})))
        end

        def self.get_loadbalancers(name, roles, role_name, services)
          LoadBalancerHelper.generate_services_with_loadbalanced_ports_by_role(roles, services).key?(role_name) ? {
            'load_balancer' => LoadBalancerHelper.generate_loadbalancer_name(name, role_name)
          } : {}
        end 

        def self.generate_auto_scaler_name(env_name, role, zones, z, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[z], 'format_autoscaling', scratch), {
                    :vpc => env_name,
                    :zone => SubnetHelpers.ZoneLiteral(z, scratch),
                    :role => role,
                    :VPC => env_name.upcase,
                    :ZONE => SubnetHelpers.ZoneLiteral(z, scratch).upcase,
                    :ROLE => role.upcase,
                    :Vpc => env_name.capitalize,
                    :Zone => SubnetHelpers.ZoneLiteral(z, scratch).capitalize,
                    :Role => role.capitalize
                })
        end

        def self.generate_launch_configuration_name(env_name, role, zones, z, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[z], 'format_launch_configuration', scratch), {
                    :vpc => env_name,
                    :zone => SubnetHelpers.ZoneLiteral(z, scratch),
                    :role => role,
                    :VPC => env_name.upcase,
                    :ZONE => SubnetHelpers.ZoneLiteral(z, scratch).upcase,
                    :ROLE => role.upcase,
                    :Vpc => env_name.capitalize,
                    :Zone => SubnetHelpers.ZoneLiteral(z, scratch).capitalize,
                    :Role => role.capitalize
                })
        end

        def self.get_default_scaling
          {
            # Defaults
            'min' => 0,
            'max' => 2,
            'desired' => 2,
          }
        end

        def self.copy_scaling_values(src)
          {}.merge(src).keep_if{|key, value|
            ["min", "max", "desired"].include?(key)
          }
        end

        def self.convert_to_autoscale_values(src)
          {
            'minimum_instances' => src['min'],
            'desired_instances' => src['desired'],
            'maximum_instances' => src['max']
          }
        end
      end
    end
  end
end

