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
require 'puppet_x/intechwifi/s3'

Puppet::Type.type(:s3_key).provide(:awscli) do
  commands :awscli => "aws"

  def create
    pair = PuppetX::IntechWIFI::S3.name_to_bucket_key_pair(@resource[:name])

    set_s3_content(pair[:bucket], pair[:key], @resource[:content])

    @property_hash[:name] = resource[:name]
    @property_hash[:content] = resource[:content]
    @property_hash[:owner] = !resource[:owner].nil? ? resource[:owner] : PuppetX::IntechWIFI::S3.get_owner_for_bucket(pair[:bucket]) {| *arg | awscli(*arg)}
    @property_hash[:grants] = resource[:grants] if !resource[:grants].nil?

    set_s3_grants(pair[:bucket], pair[:key], @property_hash[:owner], @property_hash[:grants]) if !@property_hash[:grants].nil?
    debug("created object for AWS owner=#{@property_hash[:owner]}")
  end

  def destroy
    pair = PuppetX::IntechWIFI::S3.name_to_bucket_key_pair(@resource[:name])
    awscli('s3api', 'delete-object', '--bucket', pair[:bucket], '--key', pair[:key])
  end

  def exists?
    pair = PuppetX::IntechWIFI::S3.name_to_bucket_key_pair(@resource[:name])

    data = JSON.parse(awscli('s3api', 'head-object', '--bucket', pair[:bucket], '--key', pair[:key]))
    @property_hash[:name] = @resource[:name]
    @property_hash[:content] = get_s3_content(pair[:bucket], pair[:key]) if !@resource[:content].nil? and @resource[:content].length == Integer(data["ContentLength"])

    acl = JSON.parse(awscli('s3api', 'get-object-acl', '--bucket', pair[:bucket], '--key', pair[:key]))

    @property_hash[:grants] = acl["Grants"].map{|g| PuppetX::IntechWIFI::S3.grant_json_to_property(g)}
    @property_hash[:owner] = PuppetX::IntechWIFI::S3.owner_to_property(acl["Owner"])

    true
  rescue Exception => e
    debug("EXCEPTION => #{e}")
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      pair = PuppetX::IntechWIFI::S3.name_to_bucket_key_pair(@property_hash[:name])

      set_s3_content(pair[:bucket], pair[:key], @property_flush[:content]) if !@property_flush[:content].nil?
      if !@property_flush[:grants].nil? or !@property_flush[:owner].nil?
        #  We need to set the new owner / grants...
        owner = @property_flush[:owner].nil? ? @property_hash[:owner] : @property_flush[:owner]
        grants = @property_flush[:grants].nil? ? @property_hash[:grants] : @property_flush[:grants]

        set_s3_grants(pair[:bucket], pair[:key], owner, grants)
      end
    end
  end

  def get_s3_content(bucket, key)
    file = Tempfile.open(['s3api', '.s3api'])
    awscli('s3api', 'get-object', '--bucket', bucket, '--key', key, file.path )
    file.read()
  rescue Exception => e
    ""
  end

  def set_s3_content(bucket, key, content)
    file = Tempfile.open(['s3api', '.s3api'])
    file << content
    file.close
    awscli('s3api', 'put-object', '--bucket', bucket, '--key',  key, '--body', file.path)
  end

  def set_s3_grants(bucket, key, owner, grants)
    data = {
        :Grants => grants.map{|x| PuppetX::IntechWIFI::S3.grant_property_to_hash(x)},
        :Owner => PuppetX::IntechWIFI::S3.owner_to_hash(owner)
    }.to_json

    awscli('s3api', 'put-object-acl', '--bucket', bucket, '--key', key, '--access-control-policy', data)
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def content=(value)
    @property_flush[:content] = value
  end

  def grants=(value)
    @property_flush[:grants] = value
  end

  def owner=(value)
    @property_flush[:owner] = value
  end


end
