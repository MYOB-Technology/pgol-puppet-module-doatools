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
          tags
      )

        # Validation of inputs.


        # Generate

        # Our scratch pad for storing and passing all our dynamically generated data.
        scratch = { }


        scratch[:public_zone?] = zones.has_key?('public')
        scratch[:nat_zone?] = zones.has_key?('nat')
        scratch[:private_zone?] = zones.has_key?('private')
        scratch[:tags_with_environment] = tags.merge({'Environment' => name})

        # Get our subnet sizes
        scratch[:subnet_size_data] = SubnetHelpers.CalculateCidrsForSubnets(network, zones)



        scratch[:nat_list] = NatHelpers.CalculateNatDetails(name, network, zones)
        scratch[:route_table_data] = RouteTableHelpers.CalculateRouteTablesRequired(name, network, zones, scratch)







        #  This is the data structure that we need to return, defining all resource types and  their properties.
        [
            {
                'resource_type' => "vpc",
                'resources' => {
                    name => {
                        :ensure => status,
                        :region => region,
                        :cidr   => network['cidr'],
                        :tags => scratch[:tags_with_environment],
                        :dns_hostnames => network.has_key?('dns_hostnames') ? network['dns_hostnames'] : false,
                        :dns_resolution => network.has_key?('dns_resolution') ? network['dns_resolution'] : false,
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
                } : {}).merge(
                           # Merge in the security group declarations for the roles...
                           {}
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

                } : {}).merge(
                           #  Need to merge in the security group rule declarations for the roles.
                           {}
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
                'resources' => {

                }
            },
            {
                'resource_type' => "rds_subnet_group",
                'resources' => {

                }
            },
            {
                'resource_type' => "rds",
                'resources' => {

                }
            },
            {
                'resource_type' => "launch_configuration",
                'resources' => {

                }
            },
            {
                'resource_type' => "autoscaling_group",
                'resources' => {

                }
            },
            {
                'resource_type' => "iam_role",
                'resources' => {

                }
            },
            {
                'resource_type' => "iam_policy",
                'resources' => {

                }
            },
            {
                'resource_type' => "iam_instance_profile",
                'resources' => {

                }
            },
            {
                'resource_type' => "s3_bucket",
                'resources' => {

                }
            },
            {
                'resource_type' => "s3_key",
                'resources' => {

                }
            }
        ]
      end





































      module NatHelpers
        def self.CalculateNatDetails(name, network, zones)

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
                :name => sprintf(ZoneHelpers.ZoneValue(zones['nat'], 'format'), {
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
        def self.ZoneValue(zone, value, default=nil)
          #  If the zone has a value, return it, if not - return the default value.
          zone.has_key?(value) ? zone[value] : default.nil? ? GetDefaultZoneValue(value) : default
        end

        def self.DefaltZoneValues
          {
              'ipaddr_weighting' => 1,
              'format' => "%{vpc}%{zone}%{az}",
              'ipaddr_weighting' => 1,
              'routes' => [],
              'extra_routes' => [],
          }
        end

        def self.GetDefaultZoneValue(value)
          self.DefaltZoneValues[value]
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
                :name => sprintf(ZoneHelpers.ZoneValue(zones['nat'], 'format'), {
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
              :name => sprintf(ZoneHelpers.ZoneValue(zones['private'], 'format'), {
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
                  ZoneHelpers.ZoneValue(zone, 'routes', network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes')
              ].flatten

            when 'nat'
              [
                  "0.0.0.0/0|nat|#{rt_data[:name]}",
                  ZoneHelpers.ZoneValue(zone, 'routes', network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes')
              ].flatten

            when 'private'
              [
                  ZoneHelpers.ZoneValue(zone, 'routes', network['routes']),
                  ZoneHelpers.ZoneValue(zone, 'extra_routes')
              ].flatten
            else
              []
          end
        end

      end


      module SubnetHelpers
        def self.CalculateCidrsForSubnets(network, zones)
          vpc_cidr_size = network['cidr'].split('/')[1].to_i
          total_weight = zones.keys.map{|x| ZoneHelpers.ZoneValue(zones[x],'ipaddr_weighting')}.reduce{|t, v| t = t + v}
          azs = network['availability'].length

          base_cidr = CidrMaths.CidrToLong(network['cidr'])

          cidr_data = zones.keys.map { |x|
            #  Calculate the cidr size for each zone
            [x, CidrMaths.CalculateBlockSize(vpc_cidr_size, ZoneHelpers.ZoneValue(zones[x],'ipaddr_weighting'), total_weight, azs) ]
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
              { :zone => x[0], :az => az, :cidr => CidrMaths.LongToCidr(cidr, x[1]), :index => i   }
            }
          }.flatten
        end

        def self.GenerateSubnetResources(name, status, region, network, zones, scratch, tags)
          {
              'resource_type' => "subnet",
              'resources' => scratch[:subnet_size_data].reduce({}) do |subnets, sn_data|

                subnet_name = sprintf(ZoneHelpers.ZoneValue(zones[sn_data[:zone]], 'format'), {
                    :vpc => name,
                    :az  => sn_data[:az],
                    :index => sn_data[:index],
                    :zone => sn_data[:zone],
                })

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

