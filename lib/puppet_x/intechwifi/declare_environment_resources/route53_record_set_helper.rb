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

require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/declare_environment_resources/service_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/role_helpers'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module Route53RecordSetHelper
        def self.generate(name, status, region, pg_sites, domains, scratch)
          resources = generate_records(pg_sites, domains['database_domain'], 'site_database_server')
                        .concat(generate_records(pg_sites, domains['filesystem_domain'], 'site_filesystem_server'))
                        .group_by { |record| record['hosted_zone'] }
                        .map { |hosted_zone, records| generate_record_set(name, status, region, hosted_zone, records, scratch) }
                        .reduce({}){|hash, kv| hash.merge(kv) }
          { 'resource_type' => 'route53_record_set', 'resources' => resources }
        end

        def self.generate_record_set(name, status, region, hosted_zone, records, scratch)
          {
            "#{name}-#{hosted_zone}-record-set" => {
                :ensure       => status,
                :region       => region,
                :hosted_zone  => "#{hosted_zone}.",
                :record_set   => records.map { |record| {
                  :Name =>  record['record'],
                  :Type => record['type'],
                  :Ttl => record['ttl'],
                  :Values => record['value']
                }
              }
            }
          }
        end

        def self.generate_records(pg_sites, domain, server_key)
          pg_sites.map { |site, props| {
            'hosted_zone' => domain,
            'record' => "#{site}.#{domain}.".downcase,
            'type' => 'CNAME',
            'ttl' => 60,
            'value' => [props[server_key]]
          }}
        end
      end
    end
  end
end

