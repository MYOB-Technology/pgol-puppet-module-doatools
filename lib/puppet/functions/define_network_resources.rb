require 'puppet_x/intechwifi/network_rules'

Puppet::Functions.create_function('define_network_resources') do
  def define_network_resources(status, vpc_data, zones, security_group_rules)
    # First, lets calculate the facts we need to have:

    facts = {
        :internet_gateway => zones.any?{|x| x['public_ip']},
        :nat_gateway => zones.any?{|x| !x['nat'].nil?},
        :availabilty => vpc_data['availability'],
    }

    vpc_security_group = status == 'present' ? {
        vpc_data['name'] => {
            :ensure => status,
            :region => vpc_data['region'],
            :vpc   => vpc_data['name'],
            :environment => vpc_data['environment'],

        }
    } : { }

    vpc_security_group_rules = status == 'present' ? {
        vpc_data['name'] => {
            :ensure => 'present',
            :region => vpc_data['region'],
            :in => security_group_rules[:ingress],
            :out => security_group_rules[:egress],
        }
    } : { }

    nat_gateways = facts[:nat_gateway] ?
        zones.reduce({}){ | natgw, zone |
            availability = zone['availability'].nil? ? facts[:availabilty] : zone['availability']

            if !zone['nat'].nil?
                nats = zone['nat'].kind_of?(Array) ? zone['nat'] : [ zone['nat'] ]

                availability[0..nats.length].each_with_index { |az, index|
                    nat_gateway_name = sprintf(zone['label'], {
                        :vpc => vpc_data['name'],
                        :az  => az,
                        :index => index
                    })
                    natgw[nat_gateway_name] = {
                        'ensure' => status,
                        'region' => vpc_data['region'],
                        'elastic_ip' => nats[index],
                    }
                }
            end

            natgw
        } : { }

    internet_gateway = {
        vpc_data['name'] => {
            :ensure => (facts[:internet_gateway] and status == 'present') ? 'present' : 'absent',
            :region => vpc_data['region'],
            :vpc   => vpc_data['name'],
            :nat_gateways => nat_gateways.keys,
        }
    }

    #
    # This is the Data structure we are returning...
    #

    [
        {
            'resource_type' => "vpc",
            'resources' => {
                vpc_data['name'] => {
                    :ensure => status,
                    :region => vpc_data['region'],
                    :cidr   => vpc_data['cidr'],
                    :environment => vpc_data['environment'],

                }
            }
        },
        {
            #  Public subnets use the vpc default route table.
            #  We only need to create route tables for nat gateways.
            'resource_type' => "route_table",
            'resources' => zones.reduce({}) { |route_tables, zone|
                availability = zone['availability'].nil? ? facts[:availabilty] : zone['availability']

                if !zone['nat'].nil?
                    nats = zone['nat'].kind_of?(Array) ? zone['nat'] : [ zone['nat'] ]

                    availability[0..nats.length].each.with_index { |az, index|
                        route_table_name = sprintf(zone['label'], {
                            :vpc => vpc_data['name'],
                            :az  => az,
                            :index => index
                        })
                        route_tables[route_table_name] = {
                            'ensure' => status,
                            'region' => vpc_data['region'],
                            'vpc' => vpc_data['name'],
                            'environment' => vpc_data['environment'],
                        }
                    }
                end
                route_tables
            }
        },
        {
            'resource_type' => "subnet",
            'resources' => zones.reduce({}) { |subnets, zone|
                availability = zone['availability'].nil? ? facts[:availabilty] : zone['availability']

                nats = zone['nat'].nil? ? [] : zone['nat'].kind_of?(Array) ? zone['nat'] : [ zone['nat'] ]

                subnets_without_nat = availability[nats.length..-1].map.with_index { |az, index|
                  sprintf(zone['label'], {
                      :vpc => vpc_data['name'],
                      :az  => az,
                      :index => index
                  })
                }

                default_route_table = nats.length > 0 ? sprintf(zone['label'], {
                    :vpc => vpc_data['name'],
                    :az  => availability[0],
                    :index => 0
                }) : vpc_data['name']


                availability.each.with_index { |az, index|
                    subnet_name = sprintf(zone['label'], {
                        :vpc => vpc_data['name'],
                        :az  => az,
                        :index => index
                    })

                    subnets[subnet_name] = {
                        'ensure' => status,
                        'region' => vpc_data['region'],
                        'vpc'    => vpc_data['name'],
                        'availability_zone' => az,
                        'cidr'   => PuppetX::IntechWIFI::Network_Rules.MakeCidr(zone['cidr'], index, availability.length),
                        'environment' => vpc_data['environment'],
                        'route_table' => subnets_without_nat.include?(subnet_name) ? default_route_table : subnet_name,
                        'public_ip' => zone['public_ip'].nil? ? false : zone['public_ip']
                    }

                }
                subnets
            }
        },
        {
            'resource_type' => "security_group",
            'resources' => vpc_security_group
        },
        {
            'resource_type' => "security_group_rules",
            'resources' => vpc_security_group_rules
        },
        {
            'resource_type' => "internet_gateway",
            'resources' => internet_gateway
        },
        {
            'resource_type' => "nat_gateway",
            'resources' => nat_gateways
        },
        {
            'resource_type' => "route_table_routes",
            'resources' => zones.reduce({}) { |route_table_routes, zone|
                availability = zone['availability'].nil? ? facts[:availabilty] : zone['availability']

                if !zone['nat'].nil?
                    nats = zone['nat'].kind_of?(Array) ? zone['nat'] : [ zone['nat'] ]

                    extra_subnets = availability[nats.length..-1].map.with_index { |az, index|
                      sprintf(zone['label'], {
                          :vpc => vpc_data['name'],
                          :az  => az,
                          :index => index
                      })
                    }

                    availability[1..nats.length].each.with_index { |az, index|
                        route_table_routes_name = sprintf(zone['label'], {
                            :vpc => vpc_data['name'],
                            :az  => az,
                            :index => index
                        })
                        route_table_routes[route_table_routes_name] = {
                            'ensure' => status,
                            'region' => vpc_data['region'],
                            'routes' => [
                                "0.0.0.0/0|nat|#{route_table_routes_name}",
                                "192.168.1.0/24|blackhole|none"
                            ]
                        }
                    }

                    route_table_routes_name = zone['label'] % {
                        :vpc => vpc_data['name'],
                        :az  => availability[0],
                        :index => 0,
                    }
                    route_table_routes[route_table_routes_name] = {
                        'ensure' => status,
                        'region' => vpc_data['region'],
                        'routes' => [
                            "0.0.0.0/0|nat|#{route_table_routes_name}",
                            "192.168.1.0/24|blackhole|none"
                        ]
                    }
                end
                route_table_routes
            }
        }
    ]

  end
end