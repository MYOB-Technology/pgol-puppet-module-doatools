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
        def self.generate_resources(sns_topics, vpc, status, region, scratch)
          resources = generate_sns_topics(vpc, sns_topics, scratch)
                        .map { |sns| generate_resource(vpc, region, status, sns, scratch)}
                        .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => 'sns', 'resources' => resources }
        end

        def self.generate_resource(vpc, region, status, sns, scratch)
          { sns['name'] => {
            :ensure => status, 
            :region => region,
            :sqs_success_feedback_role => sns['sqs_success_feedback_role'],
            :sqs_failure_feedback_role => sns['sqs_failure_feedback_role']
          }}
        end

        def self.generate_sns_topics(vpc, sns_topics, scratch)
          sns_topics.map { |topic| { 
                    'name' => topic,
                    'sqs_success_feedback_role' => IAMHelpers.generate_role_name(vpc, 'SNSLogRole', scratch),
                    'sqs_failure_feedback_role' => IAMHelpers.generate_role_name(vpc, 'SNSLogRole', scratch)
                  } }
                  .flatten
        end
      end
    end
  end
end

