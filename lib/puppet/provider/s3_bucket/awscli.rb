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
    @property_hash[:grants] = resource[:grants] if !resource[:grants].nil?
    @property_hash[:cors] = resource[:cors] if !resource[:cors].nil?

    #  Do we need to set a policy?
    awscli('s3api', 'put-bucket-policy','--bucket', @resource[:name], '--policy', {'Statement' => @resource[:policy]}.to_json) if !@resource[:policy].nil? and @resource[:policy].length > 0

    if !@property_hash[:grants].nil? and @property_hash[:grants].length > 0
      set_policy_args = [
          's3api',
          'put-bucket-acl',
          '--bucket', @property_hash[:name],
          '--access-control-policy', policy_json(@account, @property_hash[:grants])
      ]
      awscli(set_policy_args)
    end

    if !@property_hash[:cors].nil? and @property_hash[:cors].length > 0
      set_cors_args = [
          's3api',
          'put-bucket-cors',
          '--bucket', @property_hash[:name],
          '--cors-configuration', cors_property_to_aws(@property_hash[:cors]).to_json
      ]
      awscli(set_cors_args)
    end

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
    @account = PuppetX::IntechWIFI::S3.owner_to_property(data["Owner"])
    owner_grant = PuppetX::IntechWIFI::S3.owner_as_grant_property(data["Owner"])

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, @resource[:name] if data["Buckets"].select{|x| x["Name"] == @resource[:name]}.length != 1

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]
    @property_hash[:policy] = get_policy(@resource[:name], @resource[:region])

    acl = JSON.parse(awscli('s3api', 'get-bucket-acl', '--bucket', @property_hash[:name]))

    @property_hash[:grants] = acl["Grants"].map{|g| PuppetX::IntechWIFI::S3.grant_json_to_property(g)}.select{|x| x != owner_grant}
    @property_hash[:owner] = PuppetX::IntechWIFI::S3.owner_to_property(@account)

    @property_hash[:cors] = get_cors_from_aws(@property_hash[:region], @property_hash[:name])

    true
  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      awscli('s3api', 'put-bucket-policy','--bucket', @property_hash[:name], '--policy', {'Statement' => @property_flush[:policy]}.to_json) if !@property_flush[:policy].nil? and @property_flush[:policy].length > 0
      awscli('s3api', 'delete-bucket-policy','--bucket', @property_hash[:name]) if !@property_flush[:policy].nil? and @property_flush[:policy].length == 0

      if !@property_flush[:grants].nil?
        set_policy_args = [
            's3api',
            'put-bucket-acl',
            '--bucket', @property_hash[:name],
            '--access-control-policy', policy_json(@account, @property_flush[:grants])
        ]
        awscli(set_policy_args)
      end

      if !@property_flush[:cors].nil? and @property_flush[:cors].length  > 0
        set_cors_args = [
            's3api',
            'put-bucket-cors',
            '--bucket', @property_hash[:name],
            '--cors-configuration', cors_property_to_aws(@property_flush[:cors]).to_json
        ]
        awscli(set_cors_args)
      end

      if !@property_flush[:cors].nil? and @property_flush[:cors].length  == 0
        set_cors_args = [
            's3api',
            'delete-bucket-cors',
            '--bucket', @property_hash[:name]
        ]
        awscli(set_cors_args)
      end




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
        '--bucket', bucket,
        '--region', region
    ]

    policy = JSON.parse(awscli(args.flatten))
    JSON.parse(policy["Policy"])["Statement"]

  rescue Exception => e
    []
  end

  def get_cors_from_aws(region, bucket)
    args = [
        's3api', 'get-bucket-cors',
        '--bucket', bucket,
        '--region', region
    ]

    cors_aws_to_property(JSON.parse(awscli(args.flatten))["CORSRules"])
  rescue Exception => e
    []
  end


  def policy_json(owner, grants)
    owner_hash = PuppetX::IntechWIFI::S3.owner_to_hash(owner)
    grants.length > 0 ? PuppetX::IntechWIFI::S3.set_s3_grants_policy(owner, grants) : {
        :Grants => [{
            :Grantee => {
                :Type => "CanonicalUser",
                :DisplayName => owner_hash[:DisplayName],
                :ID => owner_hash[:ID]
            },
            :Permission => "FULL_CONTROL"
        }],
        :Owner => owner_hash
    }.to_json
  end

  def cors_aws_to_property(source)
    source.map {|x|
      {
          "verbs" => x["AllowedMethods"].select{|v| ["POST", "PUT", "GET", "HEAD", "DELETE", "*"].include? v}.map{|v| v.downcase}.sort,
          "origins" => x["AllowedOrigins"].sort
      }
    }.sort
  end

  def cors_property_to_aws(source)
    {
        "CORSRules" => source.map do |x|
          {
              "AllowedMethods" => x["verbs"].map{|v| v.upcase}.select{|v| ["POST", "PUT", "GET", "HEAD", "DELETE"].include? v},
              "AllowedOrigins" => x["origins"]
          }
        end
    }
  end
end

