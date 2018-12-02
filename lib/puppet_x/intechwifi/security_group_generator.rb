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
        class SecurityGroupGenerator
            def initialize(name, roles, services, label_format, coalesce_sgs)
                @generator = coalesce_sgs ? SgPerRoleGenerator.new(label_format) : SgPerServiceGenerator.new(label_format)
                @name = name
                @roles = roles
                @services = services
            end

            def generate(status, region, tags, db_sgs, lb_sgs)
                (status == 'present' ? [{
                    # Default security group for a vpc
                    @name => {
                        :ensure => status,
                        :region => region,
                        :vpc   => @name,
                        :tags => tags,
                    }
                }] : []
                ).concat(db_sgs.map{ |key, _val| generate_group_resource("#{@name}_#{key}", status, region, @name, tags, 'database security group') }) 
                 .concat(lb_sgs.map{ |sg| generate_group_resource(sg, status, region, @name, tags, 'load balancer security group') })        
                 .concat(@generator.generate(@name, @roles, @services, status, region, tags))
                 .reduce({}){ | hash, kv| hash.merge(kv) }
            end


            def generate_group_resource(resource_name, status, region, vpc, tags, description)
                { resource_name => { :ensure => status, :region => region, :vpc => vpc, :tags => tags, :description => description } }
            end
        end

        class SgPerServiceGenerator < SecurityGroupGenerator
            def initialize(label_format)
                @label_format = (label_format.nil? || label_format.empty?) ? '%{vpc}_%{service}' : label_format
            end

            def generate(name, roles, services, status, region, tags)
                get_service_security_groups(name, roles, services)
                    .map{ |sg, _val| generate_group_resource(sg, status, region, name, tags, 'Service security group') }
            end

            def get_service_security_groups(name, roles, services)
                services.select{ |service, service_details| get_path_value(service_details, ['network', 'in'], []).length > 0 || get_path_value(service_details, ['network', 'out'], []).length > 0 }
                        .keys
                        .map{ |service| get_security_group_name(name, service) }
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
    
            def get_security_group_name(name, service_name)
                sprintf(@label_format, {
                    :vpc => name,
                    :service => service_name,
                    :VPC => name.upcase,
                    :SERVICE => service_name.upcase,
                    :Vpc => name.capitalize,
                    :Service => service_name.capitalize,
                })
            end
        end
      
        class SgPerRoleGenerator < SecurityGroupGenerator
            def initialize(sg_label_format)
                @label_format = (sg_label_format.nil? || sg_label_format.empty?) ? '%{vpc}_%{role}' : sg_label_format
            end

            def generate
                get_role_security_groups(name, roles, services)
                    .map{ |sg, _val| generate_group_resource(sg, status, region, name, tags, 'Service security group') }
            end

            def get_role_security_groups(name, roles, services)
                
            end
        end
    end
end
  
  