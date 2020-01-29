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

Puppet::Type.type(:s3_event_notification).provide(:awscli) do
  commands :awscli => "aws"

  def create
    puts "IM IN CREATE S3 EVENT"
    config = update_config(resource[:name], resource[:endpoint], resource[:endpoint_type], resource[:events], resource[:key_prefixs], 
                           resource[:key_suffixs], resource[:bucket])
    apply_config(config)

    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:bucket] = resource[:bucket]
    @property_hash[:endpoint] = resource[:endpoint]
    @property_hash[:endpoint_type] = resource[:endpoint]
    @property_hash[:events] = resource[:events]
    @property_hash[:key_prefixs] = resource[:key_prefixs]
    @property_hash[:key_suffixs] = resource[:key_suffixs]
  end

  def destroy
    existing_config = PuppetX::IntechWIFI::AwsCmds.find_s3_bucket_notification_config(resource[:region], resource[:bucket]){ | *arg | awscli(*arg) }
    config = delete_config(resource[:name], existing_config)
    apply_config(config)
  end

  def exists?
    debug("searching for S3 Event Notification=#{resource[:name]}\n")

    bucket_config = PuppetX::IntechWIFI::AwsCmds.find_s3_bucket_notification_config(resource[:region], resource[:bucket]){ | *arg | awscli(*arg) }
    notification_type = PuppetX::IntechWIFI::Constants.notification_type_map[resource[:endpoint_type]]

    config = bucket_config["#{notification_type}Configurations"].select { |notification| notification['Id'] === resource[:name] }
                                                                .first

    puts "THIS IS S3 EVENT NOTIFI CONFIG IN EXISTS #{config}"
    return false if config.empty?
    
    grouped_rules = config['Filter']['Key']['FilterRules'].group_by { |rule| rule['Name'] }
    grouped_rules['Suffix'] = [] if grouped_rules['Suffix'].nil?
    grouped_rules['Prefix'] = [] if grouped_rules['Prefix'].nil?
    key_suffixs = grouped_rules['Suffix'].map { |rule| rule['Value'] }
    key_prefixs = grouped_rules['Prefix'].map { |rule| rule['Value'] }

    arn_parts = config["#{notification_type}Arn"].split(':')

    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:bucket] = resource[:bucket]
    @property_hash[:endpoint] = arn_parts.last
    @property_hash[:endpoint_type] = arn_parts[2]
    @property_hash[:events] = config['Events']
    @property_hash[:key_prefixs] = key_prefixs
    @property_hash[:key_suffixs] = key_suffixs

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
      config = update_config(resource[:name], resource[:endpoint], resource[:endpoint_type], resource[:events], resource[:key_prefixs], 
                             resource[:key_suffixs], resource[:bucket])
      apply_config(config)
    end
  end

  def apply_config(config)
    args = [
      's3api', 'put-bucket-notification-configuration', 
      '--bucket', resource[:bucket],
      '--notification-configuration', config.to_json
    ]

    awscli(args.flatten)
  end

  def add_lambda_permission(arn)
    puts "ADDING LAMBD PEMISSION #{arn}"
    args = [
      'lambda', 'add-permission', 
      '--function-name', arn, 
      '--principal', 's3.amazonaws.com',
      '--statement-id', "S3Invoket#{arn}", 
      '--action', 'lambda:InvokeFunction',
      '--source-arn', "arn:aws:s3:::#{@property_hash[:bucket]}"
    ]

    awscli(args.flatten)
  end

  def get_endpoint_arn(endpoint, endpoint_type)
    arn = case endpoint_type
    when 'sqs'
      # Need to implement
    when 'lambda'
      function_arn = PuppetX::IntechWIFI::AwsCmds.find_lambda_by_name(resource[:region], endpoint){ | *arg | awscli(*arg) }['Configuration']['FunctionArn']
      add_lambda_permission(function_arn)
      function_arn
    when 'sns'
      # Need to implement
    end
    arn
  end

  def update_config(name, endpoint, endpoint_type, events, key_prefixs, key_suffixs, bucket)
    begin
      config = PuppetX::IntechWIFI::AwsCmds.find_s3_bucket_notification_config(resource[:region], bucket){ | *arg | awscli(*arg) }
    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      config = {}
    end

    notification_type = PuppetX::IntechWIFI::Constants.notification_type_map[endpoint_type]
    new_config = generate_config(notification_type, name, endpoint, endpoint_type, events, key_prefixs, key_suffixs)

    if config.empty? || !config.keys.include?("#{notification_type}Configurations")
      config["#{notification_type}Configurations"] = [new_config]
    else
      config = delete_config(name, config)
      config["#{notification_type}Configurations"] = config["#{notification_type}Configurations"].push(new_config)
    end

    config
  end

  def delete_config(name, config)
    config.map { |type, notifications| { type => notifications.delete_if { |notification| notification['Id'] === name } } }
          .reduce({}){ | hash, kv| hash.merge(kv) }
  end

  def generate_config(notification_type, name, endpoint, endpoint_type, events, key_prefixs, key_suffixs)
    prefix_rules = key_prefixs.map{ |prefix| { 'Name' => 'Prefix', 'Value' => prefix } }
    suffix_rules = key_suffixs.map{ |suffix| { 'Name' => 'Suffix', 'Value' => suffix } }
    filter_rules = prefix_rules + suffix_rules

    filter = {
      'Filter' => { 
        'Key' => { 
          'FilterRules' => filter_rules 
        } 
      }
    }

    filter = {} if filter_rules.empty?

    config = {
      'Id' => name,
      "#{notification_type}Arn" => get_endpoint_arn(endpoint, endpoint_type),
      'Events' => events,
    }

    config.merge(filter)
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def bucket=(value)
    @property_flush[:bucket] = value
  end

  def endpoint=(value)
    @property_flush[:endpoint] = value
  end

  def endpoint_type=(value)
    @property_flush[:endpoint_type] = value
  end

  def events=(value)
    @property_flush[:events] = value
  end

  def region=(value)
    @property_flush[:region] = value
  end

  def key_prefixs=(value)
    @property_flush[:key_prefixs] = value
  end

  def key_suffixs=(value)
    @property_flush[:key_suffixs] = value
  end
end
