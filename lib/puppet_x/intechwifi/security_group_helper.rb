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
        
        def initialize(coalesce_sgs)
            @helper = coalesce_sgs ? SgPerRoleHelper.new : SgPerServiceHelper.new
        end

        def generate_group_resources(status, name, region, tags, db_sgs, service_sgs, lb_sgs)
            @helper.generate_group_resources(status, name, region, tags, db_sgs, service_sgs, lb_sgs)
        end
  
        def generate_group_rules_resources
            @helper.generate_group_rules_resources
        end
      end

      class SgPerServiceHelper
        def generate_group_resources(status, name, region, tags, db_sgs, service_sgs, lb_sgs)
            (status == 'present' ? {
                #  Default security group for a vpc
                name => {
                    :ensure => status,
                    :region => region,
                    :vpc   => name,
                    :tags => tags,
                }
            } : {}
            ).merge(
                # Merge in the security group declarations for the services
                service_sgs.map{|key, value|
                  {
                      key => {
                          :ensure => status,
                          :region => region,
                          :vpc => name,
                          :tags => tags,
                          :description => "Service security group"
    
                      }
                  }
                }.reduce({}){| hash, kv| hash.merge(kv)}
            ).merge(
                 # Merge in the security group declarations for the databases.
                 db_sgs.map{|key, _val|
                   {
                       "#{name}_#{key}" => {
                           :ensure => status,
                           :region => region,
                           :vpc => name,
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
                          :vpc => name,
                          :tags => tags,
                          :description => "load balancer security group"
                      }
                  }
                }.reduce({}){| hash, kv| hash.merge(kv)}
            )
        end

        def generate_group_rules_resources
        end
      end
      
      class SgPerRoleHelper
        def generate_group_resources
        end

        def generate_group_rules_resources
        end
      end

    end
  end
  
  