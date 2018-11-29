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


module PuppetX
    module IntechWIFI
        class SecurityGroupHelper
            def initialize(name, roles, services, label_format, coalesce_sgs)
                @helper = coalesce_sgs ? SgPerRoleHelper.new(label_format) : SgPerServiceHelper.new(name, roles, services, label_format)
            end

            def generate_group_resources(status, region, tags, db_sgs, lb_sgs)
                @helper.generate_group_resources(status, region, tags, db_sgs, lb_sgs)
            end
    
            def generate_group_rules_resources
                @helper.generate_group_rules_resources
            end
        end

        class SgPerServiceHelper
            def initialize(name, roles, services, label_format)
                @label_format = (label_format.nil? || label_format.empty?) ? '%{vpc}_%{service}' : label_format
                @name = name
                @roles = roles
                @services = services
            end

            def generate_group_resources(status, region, tags, db_sgs, lb_sgs)
                (status == 'present' ? {
                    #  Default security group for a vpc
                    @name => {
                        :ensure => status,
                        :region => region,
                        :vpc   => @name,
                        :tags => tags,
                    }
                } : {}
                ).merge(
                    # Merge in the security group declarations for the services
                    get_service_security_groups().map{|key, value|
                    {
                        key => {
                            :ensure => status,
                            :region => region,
                            :vpc => @name,
                            :tags => tags,
                            :description => "Service security group"
                        }
                    }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    # Merge in the security group declarations for the databases.
                    db_sgs.map{|key, _val|
                    {
                        "#{@name}_#{key}" => {
                            :ensure => status,
                            :region => region,
                            :vpc => @name,
                            :tags => tags,
                            :description => "database security group"
                        }
                    }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                ).merge(
                    # Merge in the security group declarations for the load balancers.
                    lb_sgs.map{|sg|
                    {
                        sg => {
                            :ensure => status,
                            :region => region,
                            :vpc => @name,
                            :tags => tags,
                            :description => "load balancer security group"
                        }
                    }
                    }.reduce({}){| hash, kv| hash.merge(kv)}
                )
            end

            def generate_group_rules_resources
            end

            def get_service_security_groups
                @services.select{ |service, service_details| get_path_value(service_details, ['network', 'in'], []).length > 0 || get_path_value(service_details, ['network', 'out'], []).length > 0 }
                        .map{ |service, service_details|
                                {
                                    get_service_security_group_name(service) => {
                                        :service => service,
                                        :in => get_path_value(service_details, ['network', 'in'], []).map{ |rule| transcode_rule(service, rule) }.flatten,
                                        :out => get_path_value(service_details, ['network', 'out'], []).map{ |rule| transcode_rule(service, rule) }.flatten
                                    }
                                }
                            }
                        .reduce({}){ |hash, kv| hash.merge(kv) }
            end
    
            def get_path_value(data, path, nodata)
                path = [path] unless path.kind_of?(Array)
                if !data.has_key?(path[0])
                    nodata
                elsif path.length > 1
                    get_path_value(data[path[0]], path[1..-1], nodata)
                else
                    data[path[0]]
                end
            end
    
            def get_service_security_group_name(service_name)
                sprintf(@label_format, {
                    :vpc => @name,
                    :service => service_name,
                    :VPC => @name.upcase,
                    :SERVICE => service_name.upcase,
                    :Vpc => @name.capitalize,
                    :Service => service_name.capitalize,
                })
            end
    
            def transcode_rule(service, env_format)
                segments = env_format.split('|')
    
                case segments[2]
                when 'rss'
                    location_type = 'sg'
    
                    case segments[3]
                    when 'elb'
                        # This is the fun one!
                        location_ident = @roles.select{|role_name, role_data|
                        role_data['services'].include?(service)
                        }.map{|role_name, role_data|
                        "#{@name}_#{role_name}_elb"
                        }
                    
    
                    end
    
                when 'service'
                    location_type = 'sg'
                    location_ident = [get_service_security_group_name(segments[3])]
                when 'rds'
                    location_type = 'sg'
                    location_ident = ["#{@name}_#{segments[3]}"]
                else
                    location_type = segments[2]
                    location_ident = [segments[3]]
                end
    
                location_ident.map{|loc_ident|  "#{segments[0]}|#{segments[1]}|#{location_type}|#{loc_ident}" }
            end
        end
      
        class SgPerRoleHelper
            def initialize(sg_label_format)
                @label_format = (sg_label_format.nil? || sg_label_format.empty?) ? '%{vpc}_%{role}' : sg_label_format
            end

            def generate_group_resources
            end

            def generate_group_rules_resources
            end
        end
    end
end
  
  