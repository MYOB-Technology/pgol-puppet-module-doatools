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

require 'json'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/awscmds'
require 'puppet_x/intechwifi/exceptions'

Puppet::Type.type(:lambda).provide(:awscli) do
  commands :awscli => "aws"

  LAMBDA_CONFIG_PROPERTIES = [:role, :handler, :runtime]
  LAMBDA_CODE_PROPERTIES = [:s3_bucket, :s3_key]

  def create
    args = [
        'lambda', 'create-function', 
        '--function-name', resource[:name],
        '--runtime', resource[:runtime],
        '--role', PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(resource[:role]){ |*arg| awscli(*arg) }['Arn'],
        '--handler', resource[:handler],
        '--region', resource[:region],
        '--code', "S3Bucket=#{resource[:s3_bucket]},S3Key=#{resource[:s3_key]}",
    ]

    awscli(args.flatten)

    @property_hash[:name] = resource[:name]
    @property_hash[:runtime] = resource[:runtime]
    @property_hash[:role] = resource[:role]
    @property_hash[:handler] = resource[:handler]
    @property_hash[:s3_bucket] = resource[:s3_bucket]
    @property_hash[:s3_key] = resource[:s3_key]
  end

  def destroy
    args = [
        "lambda", "delete-function", 
        "--region", resource[:region],
        "--function-name", resource[:name],
    ]
    awscli(args.flatten)
  end

  def exists?
    debug("searching for lambda=#{resource[:name]}\n")

    search = PuppetX::IntechWIFI::AwsCmds.find_lambda_by_name(resource[:region], resource[:name]){ | *arg | awscli(*arg) }
    @property_hash[:name] = resource[:name]
    @property_hash[:runtime] = search['Configuration']['Runtime']
    @property_hash[:role] = search['Configuration']['Role']
    @property_hash[:handler] = search['Configuration']['Handler']
    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def flush
    if @property_flush && @property_flush.length > 0
      update_lambda_config if @property_flush.keys.any? { |key| LAMBDA_CONFIG_PROPERTIES.include? key }
      update_lambda_code if @property_flush.keys.any? { |key| LAMBDA_CODE_PROPERTIES.include? key }
    end
  end

  def update_lambda_config
    args = [
      'lambda', 'update-function-configuration',
      '--region', resource[:region]
    ]

    args << ['--role', PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(@property_flush[:role]){ |*arg| awscli(*arg) }['Arn']] if @property_flush.key? :role
    args << ['--handler', @property_flush[:handler]] if @property_flush.key? :handler
    args << ['--runtime', @property_flush[:runtime]] if @property_flush.key? :runtime

    awscli(args.flatten)
  end
  
  def update_lambda_code
    args = [
      'lambda', 'update-function-code',
      '--function-name', resource[:name],
      '--s3-bucket', resource[:s3_bucket],
      '--s3-key', resource[:s3_key],
      '--region', resource[:region]
    ]
    awscli(args.flatten)
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def runtime=(value)
    @property_flush[:runtime] = value
  end

  def role=(value)
    @property_flush[:role] = value
  end

  def handler=(value)
    @property_flush[:handler] = value
  end

  def region=(value)
    @property_flush[:region] = value
  end

  def s3_bucket=(value)
    @property_flush[:s3_bucket] = value
  end

  def s3_key=(value)
    @property_flush[:s3_key] = value
  end
end
