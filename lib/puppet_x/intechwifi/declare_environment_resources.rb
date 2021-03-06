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
require 'puppet_x/intechwifi/declare_environment_resources/rds_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/service_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/loadbalancer_helper'
require 'puppet_x/intechwifi/declare_environment_resources/security_group_generator'
require 'puppet_x/intechwifi/declare_environment_resources/network_rules_generator'
require 'puppet_x/intechwifi/declare_environment_resources/launch_configuration_generator'
require 'puppet_x/intechwifi/declare_environment_resources/autoscaling_group_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/iam_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/lambda_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/s3_event_notification_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/sns_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/route53_record_set_helper'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources

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
          resource_type_tags,
          policies,
          label_formats,
          pg_sites,
          domains,
          lambdas,
          sns_topics,
          s3_event_notifications,
          options
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
        scratch[:label_routetable] = label_formats.has_key?('routetable') ? label_formats['routetable'] : '%{vpc}%{zone}%{az}'
        scratch[:label_zone_literals] = label_formats.has_key?('zone_literals') ? label_formats['zone_literals'] : { 'private' => 'private', 'nat' => 'nat', 'public' => 'public'}
        scratch[:label_natgw] = label_formats.has_key?('nat_gateway') ? label_formats['nat_gateway'] : '%{vpc}%{zone}%{az}'
        scratch[:label_autoscaling_group] = label_formats.has_key?('autoscaling_group') ? label_formats['autoscaling_group'] : '%{vpc}%{role}'
        scratch[:label_launch_configuration] = label_formats.has_key?('launch_configuration') ? label_formats['launch_configuration'] : '%{vpc}%{role}'
        scratch[:label_deployment_group] = label_formats.has_key?('deployment_group') ? label_formats['deployment_group'] : '%{vpc}%{deploy}'
        scratch[:label_iam_role] = label_formats.has_key?('iam_role') ? label_formats['iam_role'] : '%{vpc}%{role}'
        scratch[:label_iam_instance_profile] = label_formats.has_key?('iam_instance_profile') ? label_formats['iam_instance_profile'] : '%{vpc}%{role}'
        scratch[:label_iam_policy] = label_formats.has_key?('iam_policy') ? label_formats['iam_policy'] : '%{vpc}%{policy}'
        scratch[:label_lambda_iam_role] = label_formats.has_key?('lambda_iam_role') ? label_formats['lambda_iam_role'] : '%{lambda}-%{vpc}'
        scratch[:label_lambda] = label_formats.has_key?('lambda') ? label_formats['lambda'] : '%{lambda}-%{vpc}'
        scratch[:label_s3_event_notification] = label_formats.has_key?('s3_event_notification') ? label_formats['s3_event_notification'] : '%{service}-%{s3_event_notification}'
        scratch[:label_sns] = label_formats.has_key?('sns') ? label_formats['sns'] : '%{service}-%{sns}'

        # Get our subnet sizes
        scratch[:subnet_data] = SubnetHelpers.CalculateSubnetData(name, network, zones, scratch)

        scratch[:nat_list] = NatHelpers.CalculateNatDetails(name, network, zones, scratch)
        scratch[:route_table_data] = RouteTableHelpers.CalculateRouteTablesRequired(name, network, zones, scratch)

        # The array of rds_zones needed...
        scratch[:rds_default_zone] = ['private', 'nat', 'public'].select{ |zone| zones.has_key?(zone) }.first
        scratch[:rds_zones] = RdsHelpers.calculate_rds_zones(name, network, zones, db_servers)

        scratch[:code_deploy_service_role] = IAMHelpers.generate_role_name(name, "codedeploy", scratch)

        vpc_resources = {
            name => {
                :ensure => status,
                :region => region,
                :cidr   => network['cidr'],
                :tags => resource_type_tags['vpc'].merge(scratch[:tags_with_environment]),
                :dns_hostnames => network.has_key?('dns_hostnames') ? network['dns_hostnames'] : false,
                :dns_resolution => network.has_key?('dns_resolution') ? network['dns_resolution'] : true,
            }
        }

        route_table_resources = {
        }.merge(scratch[:route_table_data].select{|rt| status == 'present' or rt[:zone] != 'public'}.reduce({}){ |hash, rt|
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

        subnet_resources_hash = SubnetHelpers.GenerateSubnetResources(name, status, region, network, zones, scratch, resource_type_tags['subnet'].merge(scratch[:tags_with_environment]))

        security_group_generator = SecurityGroupGenerator.new(options['coalesce_sg_per_role'])
        security_group_rules_generator = NetworkRulesGenerator.new(options['coalesce_sg_per_role'])
        launch_configuration_generator = LaunchConfigurationGenerator.new(options['coalesce_sg_per_role'])

        internet_gateway_resources = {
            name => {
                :ensure => (scratch[:public_zone?] and status == 'present') ? 'present' : 'absent',
                :region => region,
                :vpc   => name,
                :nat_gateways => scratch[:nat_list].map{|nat| nat[:name]},
            }
        }

        #  This is the data structure that we need to return, defining all resource types and  their properties.
        [
          {
              'resource_type' => "vpc",
              'resources' => vpc_resources
          },
          {
              'resource_type' => "route_table",
              'resources' => route_table_resources
          },
          subnet_resources_hash,
          security_group_generator.generate(name, server_roles, services, label_formats['security_group'], status, region, scratch[:tags_with_environment], db_servers),
          security_group_rules_generator.generate(name, server_roles, services, label_formats['security_group'], status, region, db_servers),
          {
              'resource_type' => "internet_gateway",
              'resources' => internet_gateway_resources
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
                        :subnet => nat[:subnet],
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
          LoadBalancerHelper.generate_loadbalancer_resources(name, status, region, server_roles, services, scratch),
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
                      db_servers[db].dup.keep_if{|k, v| k != 'zone' }
                    )
                }
              }.flatten.reduce({}){|hash, kv| hash.merge(kv)}
          },
          launch_configuration_generator.generate(name, services, server_roles, zones, status, region, label_formats['security_group'], scratch),
          AutoscalingGroupHelpers.generate(name, services, server_roles, zones, status, region, label_formats['instance'], network, scratch),
          Route53RecordSetHelper.generate(name, status, region, pg_sites, domains, scratch),
          {
            'resource_type' => "deployment_group",
            'resources' => DeploymentGroupHelper.GenerateDeploymentGroupResources(name, server_roles, status, region, zones, scratch)
          },
          {
              'resource_type' => "iam_role",
              'resources' => IAMHelpers.calculate_all_role_resources(name, status, server_roles , services, sns_topics, scratch)
          },
          {
              'resource_type' => "iam_policy",
              'resources' => IAMHelpers.calculate_policy_resources(name, status, services, policies, scratch)
          },
          {
              'resource_type' => "iam_instance_profile",
              'resources' => IAMHelpers.calculate_instance_profile_resources(name, status, server_roles, scratch)
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
          },
          LambdaHelpers.generate_lambda_resources(lambdas, name, status, region, scratch),
          S3EventNotificationHelpers.generate_resources(s3_event_notifications, name, status, region, scratch, options),
          SNSHelpers.generate_resources(sns_topics, name, status, region, scratch)
        ]
      end

      module DeploymentGroupHelper
        def self.GenerateDeploymentGroupName(env_name, deploy, appname, scratch)
          sprintf(scratch[:label_deployment_group], {
                    :vpc => env_name,
                    :deploy => deploy,
                    :app => appname,
                    :VPC => env_name.upcase,
                    :DEPLOY => deploy.upcase,
                    :APP => appname.upcase,
                    :Vpc => env_name.capitalize,
                    :Deploy => deploy.capitalize,
                    :App => appname.capitalize,
                })
        end

        def self.DeploymentGroups?(server_roles)
          server_roles.any?{| role_name, role_data | role_data.has_key?('deploy') }
        end

        def self.GenerateDeploymentGroupResources(env_name, server_roles, status, region, zones, scratch)
          server_roles.select{| role_name, role_data | role_data.has_key?('deploy') }.map{ | role_name, role_data |
            {
              'deploy_group' => role_data['deploy']['group'],
              'role_name' => role_name,
              'deploy_application' => role_data['deploy']['deploy_application']
            }
          }.reduce({}) {| m, v |
            # if the deploy key already exists, we add the role to the array, otherwise we create it.
            m[v['deploy_group']]['roles'] << v['role_name'] if m.key?(v['deploy_group'])
            m[v['deploy_group']] = { 'roles' => [v['role_name']], 'deploy_application' => v['deploy_application'] } unless m.key?(v['deploy_group'])
            m
          }.map { |deploy , data|
            [
                GenerateDeploymentGroupName(env_name, deploy, data['deploy_application'], scratch),
                {
                    "ensure" => status,
                    "region" => region,
                    "application_name" => data['deploy_application'],
                    "service_role" => scratch[:code_deploy_service_role],
                    "autoscaling_groups" => data['roles'].map{|r|  AutoscalingGroupHelpers.generate_auto_scaler_name(env_name, r, zones, server_roles[r]['zone'], scratch) }
                }
            ]
          }.reduce({}) {|m, v| m[v[0]] = v[1]; m }
        end

      end

      module NatHelpers
        def self.GenerateNatName(env_name, zones, z, az, azi, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[z], 'format_natgw', scratch), {
                    :vpc => env_name,
                    :zone => SubnetHelpers.ZoneLiteral(z, scratch),
                    :az => az,
                    :index => azi.to_s,
                    :VPC => name.upcase,
                    :AZ => az.upcase,
                    :ZONE => SubnetHelpers.ZoneLiteral(z, scratch).upcase,
                    :Vpc => name.capitalize,
                    :Az => az.capitalize,
                    :Zone => SubnetHelpers.ZoneLiteral(z, scratch).capitalize
                })
        end

        def self.CalculateNatDetails(env_name, network, zones, scratch)

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
                :name => GenerateNatName(env_name, zones, 'nat', network['availability'][index], index, scratch),
                :az => network['availability'][index],
                :ip_addr => ipaddr,
                :subnet => SubnetHelpers.GenerateSubnetName(env_name, zones, 'public', network['availability'][index], index, scratch)
            }
          }
        end
      end

      module ZoneHelpers
        def self.ZoneValue(zone, value, scratch, default=nil)
          #  If the zone has a value, return it, if not - return the default value.
          zone.has_key?(value) ? zone[value] : default.nil? ? GetDefaultZoneValue(value, scratch) : default
        end

        def self.DefaultZoneValues
          {
              'ipaddr_weighting' => 1,
              'format' => "%{vpc}%{zone}%{az}",
              'routes' => [],
              'extra_routes' => [],
          }
        end

        def self.GetDefaultZoneValue(value, scratch)
          self.DefaultZoneValues.merge({
            'format_subnet' => scratch[:label_subnet],
            'format_routetable' => scratch[:label_routetable],
            'format_natgw' => scratch[:label_natgw],
            'format_autoscaling' => scratch[:label_autoscaling_group],
            'format_launch_configuration' => scratch[:label_launch_configuration],
            'format_iam_role' => scratch[:label_iam_role],
            'format_iam_instance_profile' => scratch[:label_iam_instance_profile],
            'format_iam_policy' => scratch[:label_iam_policy],
          })[value]
        end
      end

      module RouteTableHelpers
        def self.GenerateRouteTableName(name, zones, z, az, azi, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[z], 'format_routetable', scratch), {
                    :vpc => name,
                    :zone => SubnetHelpers.ZoneLiteral(z, scratch),
                    :az => az,
                    :index => azi.to_s,
                    :VPC => name.upcase,
                    :AZ => az.upcase,
                    :ZONE => SubnetHelpers.ZoneLiteral(z, scratch).upcase,
                    :Vpc => name.capitalize,
                    :Az => az.capitalize,
                    :Zone => SubnetHelpers.ZoneLiteral(z, scratch).capitalize
                })
        end

        def self.CalculateRouteTablesRequired(name, network, zones, scratch)
          route_tables  = []

          route_tables << {
              :name => GenerateRouteTableName(name, zones, 'public', 'all', 0, scratch),
              :zone => 'public',
              :az => nil
          } if scratch[:public_zone?]

          route_tables << scratch[:nat_list].map.with_index{|nat, index|
            {
                :name => GenerateRouteTableName(name, zones, 'nat', network['availability'][index], index, scratch),
                :zone => 'nat',
                :az => network['availability'][index]
            }
          } if scratch[:nat_zone?] and scratch[:nat_list].length > 0
          route_tables << {
              :name => GenerateRouteTableName(name, zones, 'private', 'all', 0, scratch),
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

        def self.ZoneLiteral(zone, scratch)
            scratch[:label_zone_literals].has_key?(zone) ? scratch[:label_zone_literals][zone] : zone
        end

        def self.GenerateSubnetName(name, zones, zone, az, index, scratch)
          zone_literal = SubnetHelpers.ZoneLiteral(zone, scratch)
          sprintf(ZoneHelpers.ZoneValue(zones[zone], 'format_subnet', scratch), {
              :vpc => name,
              :az  => az,
              :index => index,
              :zone => zone_literal,
              :VPC => name.upcase,
              :AZ  => az.upcase,
              :ZONE => zone_literal.upcase,
              :Vpc => name.capitalize,
              :Az  => az.capitalize,
              :Zone => zone_literal.capitalize,
          })
        end

        def self.DeTokeniseTagValues(name, tags, zones, zone, az, index, scratch)
          zone_literal = SubnetHelpers.ZoneLiteral(zone, scratch)
          tags.map { |k, v|
            [k, sprintf(v,{
              :vpc => name,
              :az  => az,
              :index => index,
              :zone => zone_literal,
              :VPC => name.upcase,
              :AZ  => az.upcase,
              :ZONE => zone_literal.upcase,
              :Vpc => name.capitalize,
              :Az  => az.capitalize,
              :Zone => zone_literal.capitalize,
            })]
          }.reduce({}) { |m, v|
            m.merge({v[0] => v[1]})
          }
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
                            :tags => DeTokeniseTagValues(name, tags, zones, sn_data[:zone], sn_data[:az], sn_data[:index], scratch),
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

