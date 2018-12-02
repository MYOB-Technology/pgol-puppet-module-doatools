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
require 'puppet_x/intechwifi/rds_helpers'
require 'puppet_x/intechwifi/loadbalancer_helper'

module PuppetX
    module IntechWIFI
        class NetworkRulesGenerator
            def initialize(name, roles, services, label_format, coalesce_sgs)
                @generator = coalesce_sgs ? NetworkRulesPerRoleGenerator.new(name, roles, services, label_format) : NetworkRulesPerServiceGenerator.new(name, roles, services, label_format)
            end

            def generate(status, region, db_servers, loadbalancers, scratch)
                @generator.generate(status, region, db_servers, loadbalancers, scratch)
            end
        end

        class NetworkRulesPerServiceGenerator < NetworkRulesGenerator
            def initialize(name, roles, services, label_format)
                @label_format = (label_format.nil? || label_format.empty?) ? '%{vpc}_%{service}' : label_format
                @name = name
                @roles = roles
                @services = services
            end

            def generate(status, region, db_servers, loadbalancers, scratch)
                security_group_rules_resources = (status == 'present' ? {
                    @name => {
                        :ensure => status,
                        :region => region,
                        :in => [],
                        :out => [],
                    }
        
                } : {}
                ).merge(
                    #  Need to merge in the security group rule declarations for the services.
                    ServiceHelpers.CalculateServiceSecurityGroups(@name, @roles, @services, scratch).map{|key, value|
                      {
                          key => {
                              :ensure => status,
                              :region => region,
                              :in => value[:in],
                              :out => value[:out],
                          }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    # Merge in the security group declarations for the databases.
                    db_servers.map{|key, value|
                      {
                          "#{@name}_#{key}" => {
                              :ensure => status,
                              :region => region,
                              :in =>  RdsHelpers.CalculateNetworkRules(@name, @services, key, value["engine"], scratch),
                              :out => [],
                          }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    loadbalancers.map{|role_name, service_array|
                      {
                          "#{@name}_#{role_name}_elb" => {
                              :ensure => status,
                              :region => region,
                              :in => service_array.map{|service| service['loadbalanced_ports']}.flatten.uniq.map{|raw_rule| "tcp|#{LoadBalancerHelper.ParseSharedPort(raw_rule)[:listen_port]}|cidr|0.0.0.0/0"},
                              :out => service_array.map{|service|
                                service['loadbalanced_ports'].map { |port|
                                  "tcp|#{LoadBalancerHelper.ParseSharedPort(port)[:target_port]}|sg|#{ServiceHelpers.CalculateServiceSecurityGroupName(@name, service["service_name"])}"
                                }
                              }.flatten.uniq,
                            }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                )
            end
        end

        class NetworkRulesPerRoleGenerator < NetworkRulesGenerator
            def initialize(sg_label_format)
                @label_format = (sg_label_format.nil? || sg_label_format.empty?) ? '%{vpc}_%{role}' : sg_label_format
            end

            def generate

            end
        end
    end
end
  
  