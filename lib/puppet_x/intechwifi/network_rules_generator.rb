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

require 'puppet_x/intechwifi/service_helpers'
require 'puppet_x/intechwifi/role_helpers'
require 'puppet_x/intechwifi/rds_helpers'
require 'puppet_x/intechwifi/loadbalancer_helper'

module PuppetX
    module IntechWIFI
        class NetworkRulesGenerator
            def initialize(name, roles, services, label_format, coalesce_sgs)
                @generator = coalesce_sgs ? NetworkRulesPerRoleGenerator.new(name, roles, services, label_format) : NetworkRulesPerServiceGenerator.new(name, roles, services, label_format)
            end

            def generate(status, region, db_servers, scratch)
                @generator.generate(status, region, db_servers, scratch)
            end

            def generate_resource(resource_name, status, region, in_rule, out_rule)
                { resource_name => { :ensure => status, :region => region, :in => in_rule, :out => out_rule } }
            end
        end

        class NetworkRulesPerServiceGenerator < NetworkRulesGenerator
            def initialize(name, roles, services, label_format)
              @label_format = (label_format.nil? || label_format.empty?) ? '%{vpc}_%{service}' : label_format
              @name = name
              @roles = roles
              @services = services
            end

            def generate(status, region, db_servers, scratch)
              security_group_rules_resources = (status == 'present' ? [{ :name => @name, :in => [], :out => [] }] : [])
                .concat(ServiceHelpers.calculate_network_rules(@name, @roles, @services, scratch))
                .concat(RdsHelpers.calculate_service_network_rules(@name, @services, db_servers, scratch))
                .concat(LoadBalancerHelper.calculate_service_network_rules(@name, @roles, @services, scratch))
                .map { |rule| generate_resource(rule[:name], status, region, rule[:in], rule[:out]) }
                .reduce({}){| hash, kv| hash.merge(kv)}
            end
        end

        class NetworkRulesPerRoleGenerator < NetworkRulesGenerator
            def initialize(name, roles, services, label_format)
              @label_format = (sg_label_format.nil? || sg_label_format.empty?) ? '%{vpc}_%{role}' : sg_label_format
              @name = name
              @roles = roles
              @services = services
            end

            def generate(status, region, db_servers, scratch)
              security_group_rules_resources = (status == 'present' ? [generate_resource(@name, status, region, { :in => [], :out => [] })] : [])
                .concat(RoleHelpers.calculate_network_rules(@name, @roles, @services, scratch))
                .concat(RdsHelpers.calculate_role_network_rules(@name, @services, db_servers, scratch))
                .concat(LoadBalancerHelper.calculate_service_network_rules(@name, @roles, @services, scratch))
                .map { |rule| generate_resource(rule[:name], status, region, rule[:in], rule[:out]) }
                .reduce({}){| hash, kv| hash.merge(kv)}
            end
        end
    end
end
  
  