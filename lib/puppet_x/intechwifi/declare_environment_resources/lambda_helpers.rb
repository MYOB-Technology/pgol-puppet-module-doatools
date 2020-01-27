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

module PuppetX
  module IntechWIFI
    module DeclareEnvironmentResources
      module LambdaHelpers
        def self.generate_lambda_resources(lambdas, vpc, status, region, scratch)
          resources = lambdas.map { |lambda_func| generate_lambda_resource(status, region, vpc, scratch, lambda_func)}
                             .reduce({}){ | hash, kv| hash.merge(kv) }
          { 'resource_type' => 'lambda', 'resources' => resources }
        end

        def self.generate_lambda_resource(status, region, vpc, scratch, lambda_func)
          {
            generate_lambda_name(vpc, lambda_func['name'], scratch) => { 
              :ensure => status, 
              :region => region, 
              :handler => lambda_func['handler'], 
              :s3_bucket => lambda_func['s3_bucket'], 
              :s3_key => lambda_func['s3_location'],
              :role => IAMHelpers.generate_lambda_role_name(vpc, lambda_func['name'], scratch),
              :runtime => lambda_func['runtime'] 
            } 
          }
        end

        def self.generate_lambda_name(vpc, function_name, scratch)
          sprintf(scratch[:label_lambda], {
                  :vpc => vpc,
                  :VPC => vpc.upcase,
                  :Vpc => vpc.capitalize,
                  :lambda => function_name,
                  :LAMBDA => function_name.upcase,
                  :Lambda => function_name.capitalize
          }).gsub('-', '') # Lambda names do not like special characters
        end
      end
    end
  end
end

