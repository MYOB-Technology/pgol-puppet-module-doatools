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
        def self.generate_resources(services, vpc, status, region, scratch, options)
          resources = generate_content_retriever_notifications(vpc, services, scratch, options)
                        .map { |s3_notification| generate_resource(vpc, region, status, s3_notification, scratch)}
                        .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => 's3_event_notification', 'resources' => resources }
        end

        def self.generate_resource(vpc, region, status, notification, scratch)
          { generate_notification_name(vpc, notification['name'], notification['service_name'], scratch) => {
            :ensure => status, 
            :region => region, 
            :bucket => notification['s3_bucket'], 
            :endpoint => notification['endpoint'], 
            :endpoint_type => notification['endpoint_type'],
            :events => notification['events'],
            :key_prefixs => check?(notification['key_prefixs']),
            :key_suffixs => check?(notification['key_suffixs'])  
          }}
        end

        def self.generate_notification_name(vpc, name, service, scratch)
          sprintf(scratch[:label_s3_event_notification], {
            :service => service,
            :SERVICE => service.upcase,
            :Service => service.capitalize,
            :s3_event_notification => name,
            :S3_EVENT_NOTIFICATIONN => name.upcase,
            :S3_Event_Notification => name.capitalize
          })
        end

        def self.generate_content_retriever_notifications(vpc, services, scratch, options)
          services.select { |service, properties| properties.key? 'content_retriever' }
                  .map { |service, properties| properties['content_retriever'].map { |retriever| retriever.merge({ 
                    'service_name' => service,
                    'events' => ['s3:ReducedRedundancyLostObject', 's3:ObjectCreated:*', 's3:ObjectRemoved:*', 's3:ObjectRestore:Post', 
                                 's3:ObjectRestore:Completed'],
                    'endpoint' => LambdaHelpers.generate_lambda_name(vpc, options['content_retriever_lambda_name'], scratch),
                    'endpoint_type' => 'lambda',
                    'key_prefixs' => retriever['s3_location'],
                    'name' => retriever['content']
                  }) } }
                  .flatten
        end

        def self.check?(property)
          return [] if property.nil?
          property
        end

      end
    end
  end
end

