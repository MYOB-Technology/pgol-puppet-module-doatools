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
require 'puppet_x/intechwifi/awscmds'

module PuppetX
  module IntechWIFI
    module Declare_Environment_Resources

      def self.define_environment_resources(
          name,
          status,     # cannot use 'ensure' as it is a reserved word in ruby.
          region,
          network,
          zones,
          server_roles,
          services,
          db_servers,
          s3,
          tags,
          tags_vpc,
          policies,
          label_formats
      )

        # Validation of inputs.
        # Generate

        # Our scratch pad for storing and passing all our dynamically generated data.
        scratch = { }


        scratch[:public_zone?] = zones.has_key?('public')
        scratch[:nat_zone?] = zones.has_key?('nat')
        scratch[:private_zone?] = zones.has_key?('private')
        scratch[:tags_with_environment] = tags.merge({'Environment' => name})
        scratch[:label_subnet] = label_formats.has_key?('subnet') ? label_formats['subnet'] : '%{vpc}%{zone}%{az}'

        # Get our subnet sizes
        scratch[:subnet_data] = SubnetHelpers.CalculateSubnetData(name, network, zones, scratch)



        scratch[:nat_list] = NatHelpers.CalculateNatDetails(name, network, zones, scratch)
        scratch[:route_table_data] = RouteTableHelpers.CalculateRouteTablesRequired(name, network, zones, scratch)


        # The array of rds_zones needed...
        scratch[:rds_default_zone] = ['private', 'nat', 'public'].select{ |zone| zones.has_key?(zone) }.first
        scratch[:rds_zones] = RdsHelpers.CalculateRdsZones(name, network, zones, db_servers)

        scratch[:service_security_groups] = ServiceHelpers.CalculateServiceSecurityGroups(name, server_roles, services)
        scratch[:loadbalancer_security_groups] = LoadBalancerHelper.CalculateSecurityGroups(name, server_roles, services)
        scratch[:loadbalancer_role_service_hash] = LoadBalancerHelper.GenerateServicesWithLoadBalancedPortsByRoleHash(server_roles, services)


        #  This is the data structure that we need to return, defining all resource types and  their properties.
        [
            {
                'resource_type' => "vpc",
                'resources' => {
                    name => {
                        :ensure => status,
                        :region => region,
                        :cidr   => network['cidr'],
                        :tags => tags_vpc.merge(scratch[:tags_with_environment]),
                        :dns_hostnames => network.has_key?('dns_hostnames') ? network['dns_hostnames'] : false,
                        :dns_resolution => network.has_key?('dns_resolution') ? network['dns_resolution'] : true,
                    }
                }
            },
            {
                'resource_type' => "route_table",
                'resources' => {}.merge(scratch[:route_table_data].select{|rt| status == 'present' or rt[:zone] != 'public'}.reduce({}){ |hash, rt|
                  hash.merge(
                      {
                          rt[:name] => {
                            :ensure=> status,
                            :region => region,
                            :vpc => name,
                            :tags => scratch[:tags_with_environment]
                          }
                      }
                  )
                })
            },
            SubnetHelpers.GenerateSubnetResources(name, status, region, network, zones, scratch, tags),
            {
                'resource_type' => "security_group",
                'resources' => (status == 'present' ? {
                    #  We can only
                    name => {
                        :ensure => status,
                        :region => region,
                        :vpc   => name,
                        :tags => scratch[:tags_with_environment],
                    }
                } : {}
                ).merge(
                    # Merge in the security group declarations for the services
                    scratch[:service_security_groups].map{|key, value|
                      {
                          key => {
                              :ensure => status,
                              :region => region,
                              :vpc => name,
                              :tags => scratch[:tags_with_environment],
                              :description => "Service security group"

                          }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                     # Merge in the security group declarations for the databases.
                     db_servers.map{|key, value|
                       {
                           "#{name}_#{key}" => {
                               :ensure => status,
                               :region => region,
                               :vpc => name,
                               :tags => scratch[:tags_with_environment],
                               :description => "database security group"
                           }
                       }
                     }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    scratch[:loadbalancer_security_groups].map{|sg|
                      {
                          "#{sg}" => {
                              :ensure => status,
                              :region => region,
                              :vpc => name,
                              :tags => scratch[:tags_with_environment],
                              :description => "load balancer security group"
                          }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                )
            },
            {
                'resource_type' => "security_group_rules",
                'resources' => (status == 'present' ? {
                    name => {
                        :ensure => status,
                        :region => region,
                        :in => [],
                        :out => [],
                    }

                } : {}
                ).merge(
                    #  Need to merge in the security group rule declarations for the roles.
                    scratch[:service_security_groups].map{|key, value|
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
                          "#{name}_#{key}" => {
                              :ensure => status,
                              :region => region,
                              :in =>  RdsHelpers::CalculateNetworkRules(name, services, key, value["engine"]),
                              :out => [],
                          }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    scratch[:loadbalancer_role_service_hash].map{|role_name, service_array|
                      {
                          "#{name}_#{role_name}_elb" => {
                              :ensure => status,
                              :region => region,
                              :in => service_array.map{|service| service['loadbalanced_ports']}.flatten.uniq.map{|raw_rule| "tcp|#{LoadBalancerHelper.ParseSharedPort(raw_rule)[:listen_port]}|cidr|0.0.0.0/0"},
                              :out => service_array.map{|service|
                                service['loadbalanced_ports'].map { |port|
                                  "tcp|#{LoadBalancerHelper.ParseSharedPort(port)[:target_port]}|sg|#{ServiceHelpers.CalculateServiceSecurityGroupName(name, service["service_name"])}"
                                }
                              }.flatten.uniq,
                            }
                      }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                )
            },
            {
                'resource_type' => "internet_gateway",
                'resources' => {
                    name => {
                        :ensure => (scratch[:public_zone?] and status == 'present') ? 'present' : 'absent',
                        :region => region,
                        :vpc   => name,
                        :nat_gateways => scratch[:nat_list].map{|nat| nat[:name]},
                    }

                }
            },
            {
                'resource_type' => "nat_gateway",
                'resources' => scratch[:nat_list].map{|nat|
                  {
                      nat[:name] => {
                          :ensure => status,
                          :region => region,
                          :elastic_ip => nat[:ip_addr],
                          :internet_gateway => name,

                      }
                  }
                }.reduce({}){|hash, item| hash.merge(item) }
            },
            {
                'resource_type' => "route_table_routes",
                'resources' => scratch[:route_table_data].map{|rt_data|
                  {
                      rt_data[:name] => {
                          :ensure => status,
                          :region => region,
                          :routes => RouteTableHelpers.CalculateRoutes(name, network, zones, scratch, rt_data)
                      }
                  }
                }.reduce({}){|hash, kv|
                  hash.merge(kv)
                }
            },
            {
                'resource_type' => "load_balancer",
                'resources' => LoadBalancerHelper.GenerateLoadbalancerResources(name, status, region, server_roles, services, scratch)
            },
            {
                'resource_type' => "rds_subnet_group",
                'resources' => [
                    # The RDS subnets that should be present.
                    scratch[:rds_zones].map{ |zone|
                      {
                          "#{name}-#{zone}" => {
                              :ensure  => status,
                              :region  => region,
                              :subnets => scratch[:subnet_data].select{|s|
                                s[:zone] == zone
                              }.map{|s|
                                s[:name]
                              }
                          }
                      }
                    },
                    # The RDS subnets that should not be present.
                    zones.keys.select{|zone_names|
                      !scratch[:rds_zones].include?(zone_names)
                    }.map{ |zone_name|
                      {
                          "#{name}-#{zone_name}" => {
                              :ensure  => 'absent',
                              :region  => region,
                          }
                      }
                    }
                ].flatten.reduce({}){|hash, kv| hash.merge(kv)  }
            },
            {
                'resource_type' => "rds",
                'resources' => db_servers.keys.map{|db|
                  {
                      "#{name}-#{db}" => {
                          'master_username' => 'admin',
                          'master_password' => 'password!',
                          'database' => "#{db}",
                          'multi_az' => 'false',
                          'public_access' => 'false',
                          'instance_type' => 'db.t2.micro',
                          'storage_size' => '50',
                      }.merge(
                          {
                              'ensure' => status,
                              'region' => region,
                              'security_groups' => [
                                  "#{name}_#{db}"
                              ],
                              'rds_subnet_group' => db_servers[db].has_key?('zone') ? "#{name}-#{db_servers[db]['zone']}"  :  "#{name}-#{scratch[:rds_default_zone]}",
                          }
                      ).merge(
                          db_servers[db].keep_if{|key, value|
                            key != 'zone'
                          }
                      )
                  }
                }.flatten.reduce({}){|hash, kv| hash.merge(kv)}
            },
            {
                'resource_type' => "launch_configuration",
                'resources' => server_roles.to_a.map{|role|
                  serverrole = {}.update(role[1])
                  {
                      "#{name}_#{role[0]}" => {
                          # Defaults

                      }.merge(
                          serverrole['ec2']
                      ).merge(
                          serverrole.keep_if{|key, value|
                            ["ssh_key_name", "userdata"].include?(key)
                          }
                      ).merge(
                           # Forced values
                           {
                               'ensure' => status,
                               'region' => region,
                               'security_groups' => ServiceHelpers.Services(role[1]).map{|service|
                                 sg = ServiceHelpers.CalculateServiceSecurityGroupName(name, service)
                               }.select{|sg|
                                 scratch[:service_security_groups].has_key?(sg)
                               },
                               'iam_instance_profile' => [
                                   IAMHelper.GenerateInstanceProfileName(name, role[0])
                               ],
                               'public_ip' => role[1]['zone'] == 'public' ? :enabled : :disabled
                           }
                      )
                  }
                }.reduce({}){|hash, kv| hash.merge(kv)}
            },
            {
                'resource_type' => "autoscaling_group",
                'resources' => server_roles.map{|role_name, role_data|

                  {
                      "#{name}_#{role_name}" => {
                          'ensure' => status,
                          'region' => region,
                          'launch_configuration' => "#{name}_#{role_name}",
                          'subnets' => scratch[:subnet_data].select{|sn|
                            sn[:zone] == role_data['zone']
                          }.map{|sn| sn[:name] },
                          #TODO: We need to set the internet gateway
                          #'internet_gateway' => nil,
                          #TODO: We need to set the nat gateway
                          #'nat_gateway' => nil,
                      }.merge(AutoScalerHelper.ConvertScalingToAutoScaleValues(
                          AutoScalerHelper.GetDefaultScaling().merge(AutoScalerHelper.CopyScalingValues(role_data.has_key?('scaling') ? role_data["scaling"] : {}))
                      )).merge(
                          scratch[:loadbalancer_role_service_hash].has_key?(role_name) ? {
                              'load_balancer' => LoadBalancerHelper.GenerateLoadBalancerName(name, role_name)
                          } : {}
                      )
                  }
                }.reduce({}){|hash, kv| hash.merge(kv)}

            },
            {
                'resource_type' => "iam_role",
                'resources' => IAMHelper.CalculateAllRoleResources(name, status, server_roles , services)
            },
            {
                'resource_type' => "iam_policy",
                'resources' => IAMHelper.CalculatePolicyResources(name, status, policies)
            },
            {
                'resource_type' => "iam_instance_profile",
                'resources' => IAMHelper.CalculateInstanceProfileResources(name, status, server_roles)
            },
            {
                'resource_type' => "s3_bucket",
                'resources' => s3.map{|bucket_name, data|
                  {
                      bucket_name => {
                          :ensure => status,
                          :region => region,
                          :policy => data['policy'],
                          :grants => data['grants'],
                          :cors => data['cors'],
                      }
                  }
                }.reduce({}){|hash, kv| hash.merge(kv)}
            },
            {
                'resource_type' => "s3_key",
                'resources' => {

                }
            }
        ]
      end






















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
                    service['loadbalanced_ports'].map{|port| ParseSharedPort(port)}
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

        def self.ParseSharedPort(shared_port)
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


      module AutoScalerHelper
        def self.GetDefaultScaling()
          {
              # Defaults
              'min' => 0,
              'max' => 2,
              'desired' => 2,
          }
        end

        def self.CopyScalingValues(src)
          {}.merge(src).keep_if{|key, value|
            ["min", "max", "desired"].include?(key)
          }
        end

        def self.ConvertScalingToAutoScaleValues(src)
          {
              'minimum_instances' => src['min'],
              'desired_instances' => src['desired'],
              'maximum_instances' => src['max'],
          }
        end
      end



      module IAMHelper
        def self.CalculatePolicyResources(name, status, policies)
          policies.map{|key,value|
            {
                GeneratePolicyName(name, key) => {
                    :ensure => status,
                    :policy => value.kind_of?(Array) ? value : [value]
                }
            }
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.CalculateAllRoleResources(name, status, server_roles, services)
          server_roles.map{|role_label, role_data|
            CalculateSingleRoleResource(name, status, role_label, role_data, services)
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.CalculateSingleRoleResource(name, status, role_label, role_data, services)
          {
              GenerateRoleName(name, role_label) => {
                  :ensure => status,
                  :policies => role_data['services'].map{|service_label|
                    service  = services[service_label]
                    service.has_key?('policies') ? service['policies'].map{|policy_label| GeneratePolicyName(name, policy_label)} : []
                  }.flatten.uniq
              }
          }
        end

        def self.CalculateInstanceProfileResources(name, status, server_roles)
          server_roles.map{|role_label, role_data|
            {
                GenerateInstanceProfileName(name, role_label) => {
                    :ensure => status,
                    :iam_role => GenerateRoleName(name, role_label)
                }
            }
          }.reduce({}){|hash, kv| hash.merge(kv)}
        end

        def self.GenerateRoleName(name, server_role_label)
          "#{name}_#{server_role_label}"
        end

        def self.GeneratePolicyName(name, policy_label)
          "#{name}_#{policy_label}"
        end

        def self.GenerateInstanceProfileName(name, instance_profile_label)
          "#{name}_#{instance_profile_label}"
        end


      end





      module RdsHelpers
        def self.CalculateRdsZones(name, network, zones, db_servers)
          # Get the zones needed for all database server declarations.
          zone_list = db_servers.keys.select{|s| db_servers[s].has_key?('zone') }.map{|s| db_servers[s]['zone']}

          # Add the default zone as well, if needed.
          zone_list << [
              'private',
              'nat',
              'public'
          ].select{ |zone|
            zones.has_key?(zone)
          }.first if db_servers.keys.select{|s| !db_servers[s].has_key?('zone') }.length > 0

          zone_list.flatten.uniq
        end

        def self.CalculateNetworkRules(name, services, db_server_name, db_server_engine)
          # First we need to find the port(s) to enable...
          ports = {
              'mysql' => [3306],
              'mariadb' =>  [3306],
              'oracle-se1' => [1525],
              'oracle-se2' => [1526],
              'oracle-se' => [1526],
              'oracle-ee' => [1526],
              'sqlserver-ee' => [1433],
              'sqlserver-se' => [1433],
              'sqlserver-ex' => [1433],
              'sqlserver-web' => [1433],
              'postgres' => [5432,5433],
              'aurora' => [3306],
          }[db_server_engine.nil? ? 'mysql' : db_server_engine]

            # Then we need the list of services that talk to this database.
            services.select{|service_name, service|
              service['network']['out'].flatten.any?{|rule|
                segments = rule.split('|')
                segments[2] == 'rds' and segments[3] == db_server_name
              }
            }.keys.map{|service_name|
              ports.map{|port| "tcp|#{port}|sg|#{ServiceHelpers.CalculateServiceSecurityGroupName(name, service_name)}"}
            }.flatten

        end
      end

      module ServiceHelpers
        def self.CalculateServiceSecurityGroups(name, roles, services)
          services.map{|key, value|
            {
                CalculateServiceSecurityGroupName(name, key) => {
                    :service => key,
                    :in => GetPathValue(value, ["network", "in"], []).map{|rule|
                      TranscodeRule(name, roles, key, rule)
                    }.flatten,
                    :out => GetPathValue(value, ["network", "out"], []).map{|rule| TranscodeRule(name, roles, key, rule)}.flatten
                }
            }
          }.reduce({}){|hash,kv| hash.merge(kv)}
        end

        def self.GetPathValue(data, path, nodata)
          path = [path] if !path.kind_of?(Array)
          if !data.has_key?(path[0])
            nodata
          elsif path.length > 1
            GetPathValue(data[path[0]], path[1..-1], nodata)
          else
            data[path[0]]
          end
        end

        def self.CalculateServiceSecurityGroupName(name, service_name)
          sprintf("%{name}_%{service}", { :name => name, :service => service_name})
        end

        def self.TranscodeRule(name, roles, service, env_format)
          segments = env_format.split('|')

          case segments[2]
            when 'rss'
              location_type = 'sg'

              case segments[3]
                when 'elb'
                  # This is the fun one!
                  location_ident = roles.select{|role_name, role_data|
                    role_data['services'].include?(service)
                  }.map{|role_name, role_data|
                    "#{name}_#{role_name}_elb"
                  }


              end

            when 'service'
              location_type = 'sg'
              location_ident = [CalculateServiceSecurityGroupName(name, segments[3])]
            when 'rds'
              location_type = 'sg'
              location_ident = ["#{name}_#{segments[3]}"]
            else
              location_type = segments[2]
              location_ident = [segments[3]]
          end

          location_ident.map{|loc_ident|  "#{segments[0]}|#{segments[1]}|#{location_type}|#{loc_ident}" }
        end

        def self.Services(role)
          role.has_key?("services") ? role["services"] : []
        end

      end


      module NatHelpers
        def self.CalculateNatDetails(name, network, zones, scratch)

          #  First we ensure we have an array of nat IP addresses (that may be zero long)
          (zones.has_key?('nat') ?
              (zones['nat']['nat_ipaddr'].kind_of?(Array) ?
                  zones['nat']['nat_ipaddr'] : [ zones['nat']['nat_ipaddr'] ] ) :
              []).select.with_index{ |ipaddr, index|
            # Then we only select enough IP's for the availability zones.
            index < network['availability'].length
          }.map.with_index{|ipaddr, index|
            # Map into a hash, containing all the details of this nat.
            {
                :name => sprintf(ZoneHelpers.ZoneValue(zones['nat'], 'format', scratch), {
                    :vpc => name,
                    :zone => 'nat',
                    :az => network['availability'][index],
                    :index => index.to_s,
                }),
                :az => network['availability'][index],
                :ip_addr => ipaddr
            }
          }
        end
      end

      module ZoneHelpers
        def self.ZoneValue(zone, value, scratch, default=nil)
          #  If the zone has a value, return it, if not - return the default value.
          zone.has_key?(value) ? zone[value] : default.nil? ? GetDefaultZoneValue(value, scratch) : default
        end

        def self.DefaltZoneValues
          {
              'ipaddr_weighting' => 1,
              'format' => "%{vpc}%{zone}%{az}",
              'routes' => [],
              'extra_routes' => [],
          }
        end

        def self.GetDefaultZoneValue(value, scratch)
          self.DefaltZoneValues.merge({'format' => scratch[:label_subnet] })[value]
        end
      end

      module RouteTableHelpers
        def self.CalculateRouteTablesRequired(name, network, zones, scratch)
          route_tables  = []

          route_tables << {
              :name => name,
              :zone => 'public',
              :az => nil
          } if scratch[:public_zone?]

          route_tables << scratch[:nat_list].map.with_index{|nat, index|
            {
                :name => sprintf(ZoneHelpers.ZoneValue(zones['nat'], 'format', scratch), {
                    :vpc => name,
                    :zone => 'nat',
                    :az => network['availability'][index],
                    :index => index.to_s,
                }),
                :zone => 'nat',
                :az => network['availability'][index]
            }
          } if scratch[:nat_zone?] and scratch[:nat_list].length > 0
          route_tables << {
              :name => sprintf(ZoneHelpers.ZoneValue(zones['private'], 'format', scratch), {
                  :vpc => name,
                  :zone => 'private',
                  :az => "",
                  :index => "",
              }),
              :zone => 'private',
              :az => nil
          } if scratch[:private_zone?]

          route_tables.flatten
        end

        def self.CalculateRoutes(name, network, zones, scratch, rt_data)
          zone = zones[rt_data[:zone]]

          case rt_data[:zone]
            when 'public'
              [
                  "0.0.0.0/0|igw|#{name}",
                  ZoneHelpers.ZoneValue(zone, 'routes', scratch, network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes', scratch)
              ].flatten

            when 'nat'
              [
                  "0.0.0.0/0|nat|#{rt_data[:name]}",
                  ZoneHelpers.ZoneValue(zone, 'routes', scratch, network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes', scratch)
              ].flatten

            when 'private'
              [
                  ZoneHelpers.ZoneValue(zone, 'routes', scratch, network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes', scratch)
              ].flatten
            else
              []
          end
        end

      end


      module SubnetHelpers
        def self.CalculateSubnetData(name, network, zones, scratch)
          vpc_cidr_size = network['cidr'].split('/')[1].to_i
          total_weight = zones.keys.map{|x| ZoneHelpers.ZoneValue(zones[x],'ipaddr_weighting', scratch)}.reduce{|t, v| t = t + v}
          azs = network['availability'].length

          base_cidr = CidrMaths.CidrToLong(network['cidr'])

          cidr_data = zones.keys.map { |x|
            #  Calculate the cidr size for each zone
            [x, CidrMaths.CalculateBlockSize(vpc_cidr_size, ZoneHelpers.ZoneValue(zones[x],'ipaddr_weighting', scratch), total_weight, azs) ]
          }.each{ |x|
            # validate CIDR is viable.
            raise CidrMaths::CidrSizeTooSmallForSubnet if x[1] > 28
          }.sort{ |a, b|
            #  Sort the zones into decending cidr size order.
            a[1] <=> b[1]
          }.map { |x|
            network['availability'].map.with_index{ |az, i|
              cidr = base_cidr
              base_cidr += CidrMaths.IpAddrsInCidrBlock(x[1])
              { :zone => x[0], :az => az, :cidr => CidrMaths.LongToCidr(cidr, x[1]), :index => i, :name => SubnetHelpers.GenerateSubnetName(name, zones, x[0], az, i, scratch) }
            }
          }.flatten
        end

        def self.GenerateSubnetName(name, zones, zone, az, index, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[zone], 'format', scratch), {
              :vpc => name,
              :az  => az,
              :index => index,
              :zone => zone,
          })
        end

        def self.GenerateSubnetResources(name, status, region, network, zones, scratch, tags)
          {
              'resource_type' => "subnet",
              'resources' => scratch[:subnet_data].reduce({}) do |subnets, sn_data|

                subnet_name = GenerateSubnetName(name, zones, sn_data[:zone], sn_data[:az], sn_data[:index], scratch)

                subnets.merge(
                    {
                        subnet_name => {
                            :ensure => status,
                            :region => region,
                            :vpc => name,
                            :availability_zone => sn_data[:az],
                            :cidr => sn_data[:cidr],
                            :tags => tags,
                            :route_table => scratch[:route_table_data].select{|rt_data|
                              # Is this route table for this subnet?
                              rt_data[:zone] == sn_data[:zone]
                            }.reduce(nil){|memo, rt_data|
                              result = nil

                              # First choice, if memo matches the AZ, we ain't changing our choice
                              result = memo if !memo.nil? and memo[:az] == sn_data[:az]

                              # Second choice, if the route applies to all AZ's then use it
                              result = rt_data if result.nil? and rt_data[:az].nil?

                              # Third choice, we have matching AZ's
                              result = rt_data if result.nil? and rt_data[:az] == sn_data[:az]

                              # Last choice if rt_data matches the first AZ then we can use this.
                              result = rt_data if result.nil? and rt_data[:az] == network['availability'][0]

                              # Still here? Then we keep our current choice
                              result = memo if result.nil?

                              result

                            }[:name],
                            :public_ip => sn_data[:zone] == "public"
                        }
                    }
                )
              end
          }
        end

      end

      module CidrMaths
        #  Isolated module containing the maths involved in CIDR calculations.

        def self.CalculateBlockSize(cidr_size, weighting, total_weighting, azs)

          ipaddrs = (((2**(32-cidr_size)) * weighting) / (azs.to_f * total_weighting)).to_i

          possible_cidr = 32
          while ipaddrs >= 2**(33-possible_cidr) do
            possible_cidr -= 1
          end

          possible_cidr
        end

        def self.CidrToLong(cidr)
          # Convert the cidr_base into a number.
          cidr.split("/")[0].split(".").map(&:to_i).reduce(0) { |sum, num| (sum << 8) + num }
        end

        def self.LongToCidr(base, size)
          (base >> 24).to_s + "." + (base >> 16 & 0xFF).to_s + "." + (base >> 8 & 0xFF).to_s + "." + (base & 0xFF).to_s + "/" + size.to_s
        end

        def self.IpAddrsInCidrBlock(size)
          ip_count = 1

          while size < 32 do
            ip_count <<= 1
            size += 1
          end
          ip_count
        end

        class CidrSizeTooSmallForSubnet < StandardError
          def initialize
            super("We must create subnets with a cidr size of at least 16 IP addresses.")
          end
        end

      end



    end
  end
end

