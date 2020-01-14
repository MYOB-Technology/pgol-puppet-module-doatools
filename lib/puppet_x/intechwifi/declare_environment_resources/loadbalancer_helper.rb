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
require 'puppet_x/intechwifi/declare_environment_resources/service_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/role_helpers'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module LoadBalancerHelper
        def self.generate_loadbalancer_resources(name, status, region, roles, services, scratch)
          load_balancer_role_service_hash = generate_services_with_loadbalanced_ports_by_role(roles, services)
          resources = get_role_names_with_load_balancers(roles, services).map{|role_name|
            generate_load_balancer(name, status, region, role_name, services, load_balancer_role_service_hash, scratch)
          }.reduce({}){|hash, kv| hash.merge(kv) }
          { 'resource_type' => 'load_balancer', 'resources' => resources }
        end

        def self.generate_load_balancer(name, status, region, role_name, services, load_balancer_role_service_hash, scratch)
          {
              "#{generate_loadbalancer_name(name, role_name)}" => {
                  :ensure => status,
                  :region => region,
                  :subnets => scratch[:subnet_data].select{|data| data[:zone] == 'public' }.map{|data| data[:name] },
                  :listeners => load_balancer_role_service_hash[role_name].map{|service|
                    service['loadbalanced_ports'].map{|port| parse_shared_port(port)}
                  }.flatten.map{|porthash|
                    (porthash.has_key?(:certificate) && porthash.has_key?(:protocol) && porthash[:protocol] === 'https') ?
                        "https://#{generate_loadbalancer_target_name(name, role_name)}:#{porthash[:listen_port]}?certificate=#{porthash[:certificate]}" :
                        "#{porthash[:protocol]}://#{generate_loadbalancer_target_name(name, role_name)}:#{porthash[:listen_port]}"
                  }.uniq,
                  :targets => [ generate_loadbalancer_target(name, role_name) ],
                  :security_groups => [ "#{name}_#{role_name}_elb" ],
                  # :internet_gateway => ;
              }
          }
        end

        def self.generate_loadbalancer_target(name, role_name)
          {
              "name" => "#{generate_loadbalancer_target_name(name, role_name)}",
              "port" => 80,
              "check_interval" => 30,
              "timeout" => 5,
              "healthy" => 5,
              "failed" => 2,
              "vpc" => name
          }
        end

        def self.generate_loadbalancer_name(name, role_name)
          transcode_loadbalancer_name("#{name}-#{role_name}")
        end

        def self.generate_loadbalancer_target_name(name, role_name)
          transcode_loadbalancer_name("#{name}-#{role_name}").downcase
        end

        def self.transcode_loadbalancer_name(name)
          name.chars.map{|ch| ['_'].include?(ch) ? '-' : ch }.join
        end

        def self.service_have_loadbalanced_ports?(services, service_name)
          return false if !services.has_key?(service_name)
          return false if !services[service_name].has_key?('loadbalanced_ports')
          return false if services[service_name]['loadbalanced_ports'].length == 0
          true
        end

        def self.get_role_loadbalanced_ports(role, services)
          return [] unless role.has_key?('services')
          role['services'].map{ |service_name|
              services[service_name].select{ |service| service.has_key?('loadbalanced_ports') && service['loadbalanced_ports'].length > 0
            }.map{ |service| service['loadbalanced_ports'] }
          }
        end

        def self.get_role_names_with_load_balancers(server_roles, services)
          server_roles.select {|role_name, role_data|
            role_data.has_key?('services') && role_data['services'].any?{|service_name| service_have_loadbalanced_ports?(services, service_name)}
          }.map{|role_name, role_data| role_name }
        end

        def self.generate_services_with_loadbalanced_ports_by_role(server_roles, services)
          server_roles.select {|role_name, role_data|
            role_data.has_key?('services') && role_data['services'].any?{|service_name| service_have_loadbalanced_ports?(services, service_name)}
          }.map{|role_name, role_data|
            {
                role_name => role_data['services'].select{|service_name|
                  service_have_loadbalanced_ports?(services, service_name)
                }.map{|service_name| services[service_name].merge({'service_name' => service_name})}
            }
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.calculate_security_groups(name, server_roles, services)
          get_role_names_with_load_balancers(server_roles, services)
            .map{|role_name| { 'name' => calculate_security_group_name(name, role_name), 'description' => 'load balancer security group' } }
        end

        def self.calculate_security_group_name(name, role_name)
          "#{name}_#{role_name}_elb"
        end

        def self.calculate_service_network_rules(name, roles, services, label_format)
          generate_services_with_loadbalanced_ports_by_role(roles, services).map{ |role_name, service_array|
            in_rules = calculate_network_in_rules(service_array)
            out_rules = service_array.map{ |service|
              service['loadbalanced_ports'].map { |port|
                "tcp|#{parse_shared_port(port)[:target_port]}|sg|#{ServiceHelpers.calculate_security_group_name(name, service['service_name'], label_format)}"
              }
            }.flatten.uniq

            { :name => calculate_security_group_name(name, role_name), :in => in_rules, :out => out_rules }
          }
        end

        def self.calculate_role_network_rules(name, roles, services, label_format)
          generate_services_with_loadbalanced_ports_by_role(roles, services).map{ |role_name, service_array|
            in_rules = calculate_network_in_rules(service_array)
            out_rules = service_array.map{ |service|
              service['loadbalanced_ports'].map { |port|
                "tcp|#{parse_shared_port(port)[:target_port]}|sg|#{RoleHelpers.calculate_security_group_name(name, role_name, label_format)}"
              }
            }.flatten.uniq

            { :name => calculate_security_group_name(name, role_name), :in => in_rules, :out => out_rules }
          }
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
end

