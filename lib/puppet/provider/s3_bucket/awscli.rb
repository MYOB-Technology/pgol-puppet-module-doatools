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
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/s3'

Puppet::Type.type(:s3_bucket).provide(:awscli) do
  commands :awscli => "aws"

  def create
    args = [
      's3api', 'create-bucket',
      '--bucket', @resource[:name],
      '--region', @resource[:region]
    ]

    awscli(args.flatten)

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]

    #  Do we need to set a policy?
    awscli('s3api', 'put-bucket-policy','--bucket', @resource[:name], '--policy', {'Statement' => @resource[:policy]}.to_json) if !@resource[:policy].nil? and @resource[:policy].length > 0


  end

  def destroy
    args = [
        's3api', 'delete-bucket',
        '--bucket', @resource[:name],
        '--region', @resource[:region]
    ]

    awscli(args.flatten)

  end

  def exists?
    args = [
        's3api', 'list-buckets'
    ]

    data = JSON.parse(awscli(args.flatten))
    @account = data["Owner"]

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, @resource[:name] if data["Buckets"].select{|x| x["Name"] == @resource[:name]}.length != 1

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]
    @property_hash[:policy] = get_policy(@resource[:name], @resource[:region])

    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      awscli('s3api', 'put-bucket-policy','--bucket', @property_hash[:name], '--policy', {'Statement' => @property_flush[:policy]}.to_json) if !@property_flush[:policy].nil? and @property_flush[:policy].length > 0
      awscli('s3api', 'delete-bucket-policy','--bucket', @property_hash[:name]) if !@property_flush[:policy].nil? and @property_flush[:policy].length == 0

    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def region=(value)
    @property_flush[:region] = value
  end

  def grants=(value)
    @property_flush[:grants] = value
  end

  def policy=(value)
    @property_flush[:policy] = value
  end

  def cors=(value)
    @property_flush[:cors] = value
  end

  #
  #  Obtain a possible policy for the bucket
  #
  def get_policy(region, bucket)
    args = [
        's3api', 'get-bucket-policy',
        '--bucket', @resource[:name],
        '--region', @resource[:region]
    ]

    policy = JSON.parse(awscli(args.flatten))
    JSON.parse(policy["Policy"])["Statement"]

  rescue Exception => e
    []
  end


end

