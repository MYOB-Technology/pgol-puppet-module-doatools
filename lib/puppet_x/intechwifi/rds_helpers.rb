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

require 'puppet_x/intechwifi/declare_environment_resources'

module PuppetX
    module IntechWIFI
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

            def self.CalculateNetworkRules(name, services, db_server_name, db_server_engine, scratch)
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
                ports.map{|port| "tcp|#{port}|sg|#{PuppetX::IntechWIFI::Declare_Environment_Resources::ServiceHelpers.CalculateServiceSecurityGroupName(name, service_name, scratch)}"}
                }.flatten

            end
        end
    end
end

