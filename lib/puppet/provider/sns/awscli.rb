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
    
    attributes = {}
    
    attributes.merge!({ 'SQSSuccessFeedbackRoleArn' => find_iam_role_arn(resource[:sqs_success_feedback_role]) }) unless resource[:sqs_success_feedback_role].nil?
    attributes.merge!({ 'SQSFailureFeedbackRoleArn' => find_iam_role_arn(resource[:sqs_failure_feedback_role]) }) unless resource[:sqs_failure_feedback_role].nil?

    args << ['--attributes', resource[:attributes].to_json]

    awscli(args.flatten)

    @property_hash[:name] = resource[:name]
    @property_hash[:sqs_success_feedback_role] = resource[:sqs_success_feedback_role]
    @property_hash[:sqs_failure_feedback_role] = resource[:sqs_failure_feedback_role]

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
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
    
    @property_hash[:sqs_success_feedback_role] = get_role_name(search['SQSSuccessFeedbackRoleArn'])
    @property_hash[:sqs_failure_feedback_role] = get_role_name(search['SQSFailureFeedbackRoleArn'])

    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def find_iam_role_arn(role_name)
    PuppetX::IntechWIFI::AwsCmds.find_iam_role_by_name(resource[:sqs_success_feedback_role]){ | *arg | awscli(*arg) }['Arn']
  end

  def get_role_name(arn)
    return '' if arn.nil?
    arn.match(/role\/(.*)/)[1]
  end

  def flush
    data = PuppetX::IntechWIFI::AwsCmds.find_sns_by_name(resource[:region], resource[:name]){ | *arg | awscli(*arg) }
    topic_arn = data['TopicArn']

    if @property_flush and @property_flush.length > 0
      args = ["sns", "set-topic-attributes", 
             '--topic-arn', topic_arn, 
             '--attribute-name', 'SQSSuccessFeedbackRoleArn', 
             '--attribute-value', find_iam_role_arn(@property_flush[:sqs_success_feedback_role])]
      awscli(args) unless @property_flush[:sqs_success_feedback_role].nil?

      args = ["sns", "set-topic-attributes", 
             '--topic-arn', topic_arn, 
             '--attribute-name', 'SQSFailureFeedbackRoleArn', 
             '--attribute-value', find_iam_role_arn(@property_flush[:sqs_failure_feedback_role])]
      awscli(args) unless @property_flush[:sqs_failure_feedback_role].nil?
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def sqs_success_feedback_role=(value)
    @property_flush[:sqs_success_feedback_role] = value
  end

  def sqs_failure_feedback_role=(value)
    @property_flush[:sqs_failure_feedback_role] = value
  end
end
