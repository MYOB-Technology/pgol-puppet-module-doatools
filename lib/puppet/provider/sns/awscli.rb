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

Puppet::Type.type(:sns).provide(:awscli) do
  commands :awscli => "aws"

  def create
    args = [
        'sns', 'create-topic', 
        '--name', resource[:name],
        '--region', resource[:region]
    ]

    args << ['--attributes', resource[:topic_attributes].to_json] unless resource[:topic_attributes].empty?

    awscli(args.flatten)

    @property_hash[:name] = resource[:name]
  end

  def destroy
    data = PuppetX::IntechWIFI::AwsCmds.find_sns_by_name(resource[:region], resource[:name]){ | *arg | awscli(*arg) }
    args = [
        "sns", "delete-topic", 
        "--topic-arn", data['TopicArn'],
        "--region", resource[:region]
    ]
    awscli(args.flatten)
  end

  def exists?
    debug("searching for sns=#{resource[:name]}\n")

    search = PuppetX::IntechWIFI::AwsCmds.find_sns_by_name(resource[:region], resource[:name]){ | *arg | awscli(*arg) }
    @property_hash[:topic_attributes] = search

    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
        new_attributes = @property_flush[:topic_attributes].merge(resource[:topic_attributes])
        topic_arn = new_attributes['TopicArn']

        new_attributes.each { |name, value| awscli(["sns", "set-topic-attributes", '--topic-arn', topic_arn, '--attribute-name', key, '--attribute-value', 'value'])}
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def topic_attributes=(value)
    @property_flush[:topic_attributes] = value
  end
end
