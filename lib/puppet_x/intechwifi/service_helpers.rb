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
    module ServiceHelpers
      DEFAULT_LABEL = '%{vpc}_%{service}'

      def self.calculate_security_groups(name, roles, services, label_format)
        services.select{ |_service, details| service_has_network?(details) }
                .map{ |service, details| {
                   'name' => calculate_security_group_name(name, service, label_format),
                   'description' => 'Service security group'
                } } 
      end

      def self.calculate_network_rules(name, roles, services, label_format)
        services.select{ |key, value| service_has_network?(value) }
                .map{ |key, value| {
                  :name => calculate_security_group_name(name, key, label_format),
                  :in => get_path_value(value, ["network", "in"], []).map{ |rule| transcode_rule(name, roles, key, rule, label_format) }.flatten,
                  :out => get_path_value(value, ["network", "out"], []).map{ |rule| transcode_rule(name, roles, key, rule, label_format)}.flatten
                } } 
      end

      def self.get_path_value(data, path, nodata)
        path = [path] if !path.kind_of?(Array)
        if !data.has_key?(path[0])
          nodata
        elsif path.length > 1
          get_path_value(data[path[0]], path[1..-1], nodata)
        else
          data[path[0]]
        end
      end
  
      def self.calculate_security_group_name(name, service_name, label_format)
        sprintf(get_label_format(label_format), {
          :vpc => name,
          :service => service_name,
          :VPC => name.upcase,
          :SERVICE => service_name.upcase,
          :Vpc => name.capitalize,
          :Service => service_name.capitalize,
        })
      end

      def self.get_label_format(label_format)
        (label_format.nil? || label_format.empty?) ? DEFAULT_LABEL : label_format
      end 
      
      def self.service_has_network?(service)
        get_path_value(service, ["network", "in"], []).length > 0 || get_path_value(service, ["network", "out"], []).length > 0
      end 

      def self.transcode_rule(name, roles, service, env_format, label_format)
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
            location_ident = [calculate_security_group_name(name, segments[3], label_format)]
          when 'rds'
            location_type = 'sg'
            location_ident = ["#{name}_#{segments[3]}"]
          else
            location_type = segments[2]
            location_ident = [segments[3]]
        end

        location_ident.map{|loc_ident|  "#{segments[0]}|#{segments[1]}|#{location_type}|#{loc_ident}" }
      end

      def self.services(role)
        role.has_key?("services") ? role["services"] : []
      end
    end
  end
end

