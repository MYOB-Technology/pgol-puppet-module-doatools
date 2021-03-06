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
require 'puppet_x/intechwifi/declare_environment_resources/rds_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/loadbalancer_helper'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      class NetworkRulesGenerator
        def initialize(coalesce_sgs)
            @generator = coalesce_sgs ? NetworkRulesPerRoleGenerator.new : NetworkRulesPerServiceGenerator.new
        end

        def generate(name, roles, services, label_format, status, region, db_servers)
            resources = (status == 'present' ? [{ :name => name, :in => [], :out => [] }] : [])
              .concat(@generator.generate(name, roles, services, label_format, db_servers))
              .map { |rule| generate_resource(rule[:name], status, region, rule[:in], rule[:out]) }
              .reduce({}){| hash, kv| hash.merge(kv)}
            { 'resource_type' => 'security_group_rules', 'resources' => resources }
        end

        def generate_resource(resource_name, status, region, in_rule, out_rule)
            { resource_name => { :ensure => status, :region => region, :in => in_rule, :out => out_rule } }
        end
      end

      class NetworkRulesPerServiceGenerator
        def generate(name, roles, services, label_format, db_servers)
          ServiceHelpers.calculate_network_rules(name, roles, services, label_format)
            .concat(RdsHelpers.calculate_service_network_rules(name, services, db_servers, label_format))
            .concat(LoadBalancerHelper.calculate_service_network_rules(name, roles, services, label_format))
        end
      end

      class NetworkRulesPerRoleGenerator
        def generate(name, roles, services, label_format, db_servers)
          RoleHelpers.calculate_network_rules(name, roles, services, label_format)
            .concat(RdsHelpers.calculate_role_network_rules(name, roles, services, db_servers, label_format))
            .concat(LoadBalancerHelper.calculate_service_network_rules(name, roles, services, label_format))
        end
      end
    end
  end
end
  
  