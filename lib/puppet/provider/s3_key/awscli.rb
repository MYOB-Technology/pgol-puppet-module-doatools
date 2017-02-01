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

Puppet::Type.type(:s3_key).provide(:awscli) do
  commands :awscli => "aws"

  def create
    pair = name_to_bucket_key_pair(@resource[:name])

    set_s3_content(pair[:bucket], pair[:key], @resource[:content])

    @property_hash[:name] = resource[:name]
    @property_hash[:content] = resource[:content]
  end

  def destroy
    pair = name_to_bucket_key_pair(@resource[:name])
    awscli('s3api', 'delete-object', '--bucket', pair[:bucket], '--key', pair[:key])
  end

  def exists?
    pair = name_to_bucket_key_pair(@resource[:name])

    data = JSON.parse(awscli('s3api', 'head-object', '--bucket', pair[:bucket], '--key', pair[:key]))
    @property_hash[:name] = @resource[:name]
    @property_hash[:content] = get_s3_content(pair[:bucket], pair[:key]) if !@resource[:content].nil? and @resource[:content].length == Integer(data["ContentLength"])

    true
  rescue Exception => e
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      pair = name_to_bucket_key_pair(@property_hash[:name])

      set_s3_content(pair[:bucket], pair[:key], @property_flush[:content]) if !@property_flush[:content].nil?

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

  def name_to_bucket_key_pair(name)
    # we need to check if we have a path on the end...
    append = name[-1] == '/'? "/" : ""
    arr = name.split('/')
    {
        :bucket => arr[2],
        :key => arr[3..arr.length].join("/") + append
    }
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def content=(value)
    @property_flush[:content] = value
  end


end
