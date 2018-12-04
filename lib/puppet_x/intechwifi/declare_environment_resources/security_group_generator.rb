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

require 'puppet_x/intechwifi/declare_environment_resources/service_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/loadbalancer_helper'
require 'puppet_x/intechwifi/declare_environment_resources/rds_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/role_helpers'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      class SecurityGroupGenerator
        def initialize(coalesce_sgs)
          @generator = coalesce_sgs ? SgPerRoleGenerator.new : SgPerServiceGenerator.new
        end
  
        def generate(name, roles, services, label_format, status, region, tags, db_servers)
          @generator.generate(name, roles, services, status, region, tags, label_format)
            .concat(LoadBalancerHelper.calculate_security_groups(name, roles, services))
            .concat(RdsHelpers.calculate_security_groups(name, db_servers))
            .map{ |sg| generate_group_resource(sg['name'], status, region, name, tags, sg['description']) }        
            .reduce({}){ | hash, kv| hash.merge(kv) }
            .merge( (status == 'present') ? { name => {:ensure => status, :region => region, :vpc => name, :tags => tags } } : {})
        end
  
        def generate_group_resource(resource_name, status, region, vpc, tags, description)
          { resource_name => { :ensure => status, :region => region, :vpc => vpc, :tags => tags, :description => description } }
        end
      end
  
      class SgPerServiceGenerator
        def generate(name, roles, services, status, region, tags, label_format)
          ServiceHelpers.calculate_security_groups(name, roles, services, label_format)
        end
      end
  
      class SgPerRoleGenerator
        def generate(name, roles, services, status, region, tags, label_format)
          RoleHelpers.calculate_security_groups(name, roles, services, label_format)
        end
      end
    end
  end
end
