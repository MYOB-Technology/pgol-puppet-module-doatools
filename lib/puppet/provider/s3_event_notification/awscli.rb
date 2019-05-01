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

  CONFIGURATIONS = ['TopicConfigurations', 'QueueConfigurations', 'LambdaFunctionConfigurations']

  def create
    config = update_config(resource[:name], resource[:endpoint_arn], resource[:events], resource[:key_prefixs], resource[:key_suffixs], resource[:bucket])

    args = [
      's3api', 'put-bucket-notification-configuration', 
      '--bucket', resource[:bucket],
      '--notification-configuration', config.to_json
    ]

    awscli(args.flatten)

    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:bucket] = resource[:bucket]
    @property_hash[:endpoint_arn] = resource[:endpoint_arn]
    @property_hash[:events] = resource[:events]
    @property_hash[:key_prefixs] = resource[:key_prefixs]
    @property_hash[:key_suffixs] = resource[:key_suffixs]
  end

  def destroy
    existing_config = get_config(bucket)
    config = delete_config(resource[:name], existing_config)

    args = [
      's3api', 'put-bucket-notification-configuration', 
      '--bucket', resource[:bucket],
      '--notification-configuration', config.to_json
    ]

    awscli(args.flatten)
  end

  def exists?
    debug("searching for S3 Event Notification=#{resource[:name]}\n")

    bucket_config = get_config(resource[:bucket])
    notification_type = get_notification_type(resource[:endpoint_arn])

    config = bucket_config["#{notification_type}Configurations"].select { |notification| notification['Id'] === resource[:name] }

    return false if config.empty?

    grouped_rules = config['Filter']['Key']['FilterRules'].groupBy { |rule| rule['Key'] }
    key_suffixs = groups_rules['suffix'].map { |rule| rule['Value'] }
    key_prefixs = groups_rules['prefix'].map { |rule| rule['Value'] }

    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:bucket] = resource[:bucket]
    @property_hash[:endpoint_arn] = config["#{notification_type}Arn"]
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
      config = update_config(resource[:name], resource[:endpoint_arn], resource[:events], resource[:key_prefixs], resource[:key_suffixs], resource[:bucket])

      args = [
        's3api', 'put-bucket-notification-configuration', 
        '--bucket', resource[:bucket],
        '--notification-configuration', config.to_json
      ]
  
      awscli(args.flatten)
    end
  end

  def get_config(bucket)
    PuppetX::IntechWIFI::AwsCmds.find_s3_bucket_notification_config(resource[:region], resource[:bucket]){ | *arg | awscli(*arg) }
  end

  def get_notification_type(endpoint_arn)
    arn_parts = endpoint_arn.split(':')
    type = case arn_parts[2] 
      when 'sqs'
        'Queue'
      when 'lambda'
        'LambdaFunction'
      when 'sns'
        'Topic'
    end
    type
  end

  def update_config(name, endpoint_arn, events, key_prefixs, key_suffixs, bucket)
    begin
      config = get_config(bucket)
    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
      config = {}
    end

    notification_type = get_notification_type(endpoint_arn)
    new_config = generate_config(notification_type, name, endpoint_arn, events, key_prefixs, key_suffixs)

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

  def generate_config(notification_type, name, endpoint_arn, events, key_prefixs, key_suffixs)
    prefix_rules = key_prefixs.map{ |prefix| { 'Name' => 'Prefix', 'Value' => prefix } }
    suffix_rules = key_suffixs.map{ |suffix| { 'Name' => 'Suffix', 'Value' => suffic } }
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
      "#{notification_type}Arn" => endpoint_arn,
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

  def endpoint_arn=(value)
    @property_flush[:endpoint_arn] = value
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
