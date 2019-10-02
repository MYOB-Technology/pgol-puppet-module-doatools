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

require 'puppet_x/intechwifi/declare_environment_resources/iam_helpers'
require 'puppet_x/intechwifi/declare_environment_resources/lambda_helpers'

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module S3EventNotificationHelpers
        def self.generate_resources(s3_event_notifications, vpc, status, region, scratch, options)
          resources =  s3_event_notifications.map { |notification| generate_resource(vpc, region, status, notification, scratch)}
                        .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => 's3_event_notification', 'resources' => resources }
        end

        def self.generate_resource(vpc, region, status, notification, scratch)
          { notification['name'] => {
            :ensure => status, 
            :region => region, 
            :bucket => notification['bucket'], 
            :endpoint => generate_endpoint_name(vpc, notification, scratch), 
            :endpoint_type => notification['endpoint_type'],
            :events => notification['events'],
            :key_prefixs => check?(notification['key_prefixs']),
            :key_suffixs => check?(notification['key_suffixs'])  
          }}
        end

        def self.generate_endpoint_name(vpc, notification, scratch)
          LambdaHelpers.generate_lambda_name(vpc, notification['endpoint'], scratch) if notification['endpoint_type'] === 'lambda'
        end

        def self.check?(property)
          return [] if property.nil?
          property
        end

      end
    end
  end
end

