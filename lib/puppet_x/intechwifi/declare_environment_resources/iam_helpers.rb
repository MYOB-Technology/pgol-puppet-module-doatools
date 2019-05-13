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
require 'active_support/core_ext/string'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module IAMHelpers
        def self.calculate_policy_resources(name, status, services, policies, scratch)  
          all_policies =  services.select { |service, properties| properties.key? 'lambdas' }  
                                  .map{ |_service, properties| properties['lambdas'] } 
                                  .flatten
                                  .map { |lambda_func| lambda_func['policies']}
                                  .flatten
                                  .reduce({}){|hash, kv| hash.merge(kv){ |key, oldval, newval| oldval.concat(newval) } }
                                  .merge(policies) { |key, oldval, newval| oldval.concat(newval) }

          all_policies.map{|key,value|
            {
                generate_policy_name(name, key, scratch) => {
                    :ensure => status,
                    :policy => value.kind_of?(Array) ? value : [value]
                }
            }
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.calculate_all_role_resources(name, status, server_roles, services, scratch)
          roles = server_roles.map{|role_label, role_data|
            calculate_single_role_resource(name, status, role_label, role_data, services, scratch)
          }

          roles.concat(calculate_lambda_roles(name, status, services, scratch))

          roles <<  {
             "#{scratch[:code_deploy_service_role]}" => {
               :ensure => status,
               :policies => [ "AWSCodeDeployRole" ],
               :trust => [ "codedeploy" ],
             }
           } if DeploymentGroupHelper.DeploymentGroups?(server_roles)

          roles.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.calculate_single_role_resource(name, status, role_label, role_data, services, scratch)
          {
              generate_role_name(name, role_label, scratch) => {
                  :ensure => status,
                  :policies => role_data['services'].map{|service_label|
                    service  = services[service_label]
                    service.has_key?('policies') ? service['policies'].map{|policy_label| generate_policy_name(name, policy_label, scratch)} : []
                  }.flatten.uniq
              }
          }
        end

        def self.calculate_instance_profile_resources(name, status, server_roles, scratch)
          server_roles.map{|role_label, role_data|
            {
                generate_instance_profile_name(name, role_label, scratch) => {
                    :ensure => status,
                    :iam_role => generate_role_name(name, role_label, scratch)
                }
            }
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.calculate_lambda_roles(name, status, services, scratch)
          services.select { |service, properties| properties.key? 'lambdas' }
                  .map { |_service, properties| properties['lambdas'] }
                  .flatten
                  .map { |lambda_function| {
                    generate_lambda_role_name(name, lambda_function['name'], scratch) => {
                      :ensure => status, 
                      :policies => lambda_function['policies'].reduce({}){|hash, kv| hash.merge(kv)}
                                                              .keys 
                                                              .map{ |policy| generate_policy_name(name, policy, scratch) },
                      :trust => [ 'lambda' ]
                    }
                  }}
        end 

        def self.generate_role_name(name, role, scratch)
          sprintf(scratch[:label_iam_role], {
                    :vpc => name,
                    :VPC => name.upcase,
                    :Vpc => name.capitalize,
                    :role => role,
                    :ROLE => role.upcase,
                    :Role => role.capitalize,
                })
        end

        def self.generate_lambda_role_name(name, lambda_function, scratch)
          sprintf(scratch[:label_lambda_iam_role], {
                    :vpc => name,
                    :VPC => name.upcase,
                    :Vpc => name.capitalize,
                    :lambda => lambda_function,
                    :LAMBDA => lambda_function.upcase,
                    :Lambda => lambda_function.capitalize,
                }).truncate(64)
        end

        def self.generate_policy_name(name, policy, scratch)
          sprintf(scratch[:label_iam_policy], {
                    :vpc => name,
                    :VPC => name.upcase,
                    :Vpc => name.capitalize,
                    :policy => policy,
                    :POLICY => policy.upcase,
                    :Policy => policy.capitalize,
                })
        end

        def self.generate_instance_profile_name(name, role, scratch)
          sprintf(scratch[:label_iam_instance_profile], {
                    :vpc => name,
                    :VPC => name.upcase,
                    :Vpc => name.capitalize,
                    :role => role,
                    :ROLE => role.upcase,
                    :Role => role.capitalize,
                })
        end
      end
    end
  end
end

