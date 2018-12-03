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

require 'puppet_x/intechwifi/exceptions'

module PuppetX
    module IntechWIFI
        module LoadBalancerHelper
            def self.GenerateLoadbalancerResources(name, status, region, roles, services, scratch)
              GetRoleNamesWithLoadBalancers(roles, services).map{|role_name|
                GenerateLoadBalancer(name, status, region, role_name, services, scratch)
              }.reduce({}){|hash, kv| hash.merge(kv) }
            end
    
            def self.GenerateLoadBalancer(name, status, region, role_name, services, scratch)
              {
                  "#{GenerateLoadBalancerName(name, role_name)}" => {
                      :ensure => status,
                      :region => region,
                      :subnets => scratch[:subnet_data].select{|data| data[:zone] == 'public' }.map{|data| data[:name] },
                      :listeners => scratch[:loadbalancer_role_service_hash][role_name].map{|service|
                        service['loadbalanced_ports'].map{|port| parse_shared_port(port)}
                      }.flatten.map{|porthash|
                        (porthash.has_key?(:certificate) and porthash.has_key?(:protocol) and porthash[:protocol] == 'https') ?
                            "https://#{GenerateLoadBalancerTargetName(name, role_name)}:#{porthash[:listen_port]}?certificate=#{porthash[:certificate]}" :
                            "#{porthash[:protocol]}://#{GenerateLoadBalancerTargetName(name, role_name)}:#{porthash[:listen_port]}"
                      }.uniq,
                      :targets => [ GenerateLoadBalancerTarget(name, role_name) ],
                      :security_groups => [ "#{name}_#{role_name}_elb" ],
                      # :internet_gateway => ;
                  }
              }
            end
    
            def self.GenerateLoadBalancerTarget(name, role_name)
              {
                  "name" => "#{GenerateLoadBalancerTargetName(name, role_name)}",
                  "port" => 80,
                  "check_interval" => 30,
                  "timeout" => 5,
                  "healthy" => 5,
                  "failed" => 2,
                  "vpc" => name
              }
            end
    
            def self.GenerateLoadBalancerName(name, role_name)
              TranscodeLoadBalancerName("#{name}-#{role_name}")
            end
    
            def self.GenerateLoadBalancerTargetName(name, role_name)
              TranscodeLoadBalancerName("#{name}-#{role_name}")
            end
    
            def self.TranscodeLoadBalancerName(name)
              name.chars.map{|ch| ['_'].include?(ch) ? '-' : ch }.join
            end
    
            def self.DoesServiceHaveLoadbalancedPorts(services, service_name)
              return false if !services.has_key?(service_name)
              return false if !services[service_name].has_key?('loadbalanced_ports')
              return false if services[service_name]['loadbalanced_ports'].length == 0
              true
            end
    
            def self.GetRoleLoadBalancedPorts(role, services)
              return [] if !role.has_key?('services')
    
              role['services'].map{ |service_name|
                services[service_name].select{|service|
                  service.has_key?('loadbalanced_ports') and service['loadbalanced_ports'].length > 0
                }.map{|service|
                  service['loadbalanced_ports']
                }
              }
            end
    
            def self.GetRoleNamesWithLoadBalancers(server_roles, services)
              server_roles.select {|role_name, role_data|
                role_data.has_key?('services') and role_data['services'].any?{|service_name| DoesServiceHaveLoadbalancedPorts(services, service_name)}
              }.map{|role_name, role_data| role_name }
            end
    
            def self.GenerateServicesWithLoadBalancedPortsByRoleHash(server_roles, services)
              server_roles.select {|role_name, role_data|
                role_data.has_key?('services') and role_data['services'].any?{|service_name| DoesServiceHaveLoadbalancedPorts(services, service_name)}
              }.map{|role_name, role_data|
                {
                    role_name => role_data['services'].select{|service_name|
                      DoesServiceHaveLoadbalancedPorts(services, service_name)
                    }.map{|service_name| services[service_name].merge({'service_name' => service_name})}
                }
              }.reduce({}){|hash, kv| hash.merge(kv)}
            end
    
            def self.CalculateSecurityGroups(name, server_roles, services)
              GetRoleNamesWithLoadBalancers(server_roles, services).map{|role_name| "#{name}_#{role_name}_elb"}
            end

            def self.calculate_service_network_rules(service_array, scratch)
              in_rules = calculate_network_in_rules(service_array)
              out_rules = service_array.map{ |service|
                service['loadbalanced_ports'].map { |port|
                  "tcp|#{parse_shared_port(port)[:target_port]}|sg|#{ServiceHelpers.CalculateServiceSecurityGroupName(@name, service["service_name"], scratch)}"
                }
              }.flatten.uniq

              { :in => in_rules, :out => out_rules }
            end

            def self.calculate_role_network_rules(role_name, service_array, scratch)
              in_rules = calculate_network_in_rules(service_array)
              out_rules = service_array.map{ |service|
                service['loadbalanced_ports'].map { |port|
                  "tcp|#{parse_shared_port(port)[:target_port]}|sg|#{ServiceHelpers.calculate_role_security_group(@name, role_name, scratch)}"
                }
              }.flatten.uniq
            end

            def self.calculate_network_in_rules(service_array)
              in_rules = service_array.map{|service| service['loadbalanced_ports']}.flatten.uniq.map{|raw_rule| "tcp|#{parse_shared_port(raw_rule)[:listen_port]}|cidr|0.0.0.0/0"}
            end 
    
            def self.parse_shared_port(shared_port)
              source_target_split = /^(.+)=>([0-9]{1,5})$/.match(shared_port)
    
              # no =>
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, shared_port if source_target_split.nil?
              # Destination port a number?
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, source_target_split[2] if /^[0-9]{1,5}$/.match(source_target_split[2]).nil?
    
              source_split = source_target_split[1].split('|')
    
              # Was it properly split?
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, shared_port if source_target_split.nil?
              # too few segments?
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, shared_port if source_split.length < 2
              # too many segments?
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, shared_port if source_split.length > 3
    
              # Is the source port a number?
              raise PuppetX::IntechWIFI::Exceptions::SharedPortFormatError, shared_port if /^[0-9]{1,5}$/.match(source_split[1]).nil?
    
              {
                  :protocol => source_split[0],
                  :listen_port => source_split[1],
                  :target_port => source_target_split[2]
              }.merge(source_split.length == 3 ? {
                  :certificate => source_split[2]
              } : {})
    
            end
        end
    end
end

