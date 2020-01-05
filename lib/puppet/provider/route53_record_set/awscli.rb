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
require 'tempfile'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/awscmds'
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/ebs_volumes'

Puppet::Type.type(:route53_record_set).provide(:awscli) do
  commands :awscli => "aws"

  def create
    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    @property_hash[:record_set] = resource[:record_set]
    @property_hash[:hosted_zone] = resource[:hosted_zone]
    update_record_set(@property_hash[:region], @property_hash[:hosted_zone], resource[:record_set], resource[:name], 'UPSERT')
  end


  def generate_change_set(record_set, hosted_zone_id, action)
    changes_array = record_set.map { |record|
      {
        'Action' => action,
        'ResourceRecordSet' => {
          'Name' => record[:Name],
          'Type' => record[:Type],
          'TTL'  => record[:Ttl],
          'ResourceRecords' => record[:Values].map { |value| { 'Value' => value } } 
        }
      }
    }
    {
      'Changes' => changes_array,
      'Comment' => "Resource record set changes for Hosted Zone #{hosted_zone_id}"
    }
  end

  def update_record_set(region, hosted_zone, record_set, resource_name, action)
    hosted_zone_comment = resource_name.gsub(/-record-set$/, '')
    hosted_zone_id = PuppetX::IntechWIFI::AwsCmds.find_hosted_zone_id_by_name(region, hosted_zone, hosted_zone_comment) { |*arg| awscli(*arg) }['Id']

    record_change_set_file = Tempfile.new('record_change_set_file')
    record_change_set_file.write(generate_change_set(record_set, hosted_zone_id, action).to_json)
    record_change_set_file.close 

    args = [
        'route53', 'change-resource-record-sets',
        '--hosted-zone-id', hosted_zone_id,
        '--change-batch', "file://#{record_change_set_file.path}"
    ]

    awscli(args.flatten)
  end

  def destroy
    update_record_set(@property_hash[:region], @property_hash[:hosted_zone], resource[:record_set], resource[:name], 'DELETE')
  end

  def exists?
    @property_hash[:region] = resource[:region]
    @property_hash[:hosted_zone] = resource[:hosted_zone]
    hosted_zone_comment = resource[:name].gsub(/-record-set$/, '')
    hosted_zone_id = PuppetX::IntechWIFI::AwsCmds.find_hosted_zone_id_by_name(@property_hash[:region], @property_hash[:hosted_zone], hosted_zone_comment) { |*arg| awscli(*arg) }['Id']

    resource_record_set = []
    args = [
      'route53', 'list-resource-record-sets',
      '--hosted-zone-id', hosted_zone_id
    ]

    resource_record_sets = JSON.parse(awscli(args.flatten))['ResourceRecordSets'].reject { |record| record['Name'] == @property_hash[:hosted_zone] } 
    @property_hash[:record_set] = resource_record_sets.map { |resource_record_set| {
                                    :Name => resource_record_set['Name'],
                                    :Type => resource_record_set['Type'],
                                    :Ttl => resource_record_set['TTL'],
                                    :Values => resource_record_set['ResourceRecords'].map { |record| record['Value'] }
                                  }}
    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      update_record_set(@property_hash[:region], @property_hash[:hosted_zone], resource[:record_set], resource[:name], 'UPSERT')
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods
  
  def record_set=(value)
    @property_flush[:record_set] = value
  end

  def region=(value)
    @property_flush[:region] = value
  end

  def hosted_zone=(value)
    @property_flush[:hosted_zone] = value
  end
end