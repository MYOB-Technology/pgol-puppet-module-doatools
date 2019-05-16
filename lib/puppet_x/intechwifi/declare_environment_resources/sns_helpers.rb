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
      module SNSHelpers
        def self.generate_resources(services, vpc, status, region, scratch)
          resources = generate_content_retriever_topics(vpc, services, scratch)
                        .map { |sns| generate_resource(vpc, region, status, sns, scratch)}
                        .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => 'sns', 'resources' => resources }
        end

        def self.generate_resource(vpc, region, status, sns, scratch)
          { generate_sns_name(vpc, sns['name'], sns['service_name'], scratch) => {
            :ensure => status, 
            :region => region
          }}
        end

        def self.generate_sns_name(vpc, name, service, scratch)
          sprintf(scratch[:label_sns], {
            :service => service,
            :SERVICE => service.upcase,
            :Service => service.capitalize,
            :sns => name,
            :SNS => name.upcase,
            :Sns => name.capitalize
          })
        end

        def self.generate_content_retriever_topics(vpc, services, scratch)
          services.select { |service, properties| properties.key? 'content_retriever' }
                  .map { |service, properties| properties['content_retriever'].map { |retriever| retriever.merge({ 
                    'service_name' => service,
                    'name' => retriever['content']
                  }) } }
                  .flatten
        end

        def self.sns_content_retrievers?(services)
          services.select { |service, properties| properties.key? 'content_retriever' }
                  .map { |service, properties| properties['content_retriever'] }
                  .flatten
                  .map { |content_retriever| !content_retriever.empty? }
                  .any?
        end
      end
    end
  end
end

