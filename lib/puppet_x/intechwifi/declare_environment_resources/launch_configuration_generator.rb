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

require 'puppet_x/intechwifi/declare_environment_resources/launch_configuration_helpers'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      class LaunchConfigurationGenerator
        def initialize(coalesce_sgs)
          @generator = coalesce_sgs ? RoleDrivenLaunchConfiguration.new : ServiceDrivenLaunchConfiguration.new
        end
  
        def generate(name, services, roles, zones, status, region, sg_label_format, scratch)
          resources = @generator.generate(name, services, roles, zones, sg_label_format, scratch)
            .map { |launch_config| generate_group_resource(launch_config, status, region) }
            .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => "launch_configuration", 'resources' => resources }
        end
  
        def generate_group_resource(launch_config, status, region)
          { launch_config['name'] => 
              launch_config.reject { |key , _val| key == 'name' }
                           .merge({ 'ensure' => status, 'region' => region })
          }
        end
      end
  
      class ServiceDrivenLaunchConfiguration
        def generate(name, services, roles, zones, sg_label_format, scratch)
          LaunchConfigurationHelpers.get_service_based_launch_configuration(name, services, roles, zones, sg_label_format, scratch)
        end
      end
  
      class RoleDrivenLaunchConfiguration
        def generate(name, services, roles, zones, sg_label_format, scratch)
          LaunchConfigurationHelpers.get_role_based_launch_configuration(name, services, roles, zones, sg_label_format, scratch)
        end
      end
    end
  end
end
