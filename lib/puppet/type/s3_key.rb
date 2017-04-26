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

require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/s3'

Puppet::Type.newtype(:s3_key) do
  desc <<-DESC
  The s3_key models a single AWS S3 object in puppet.
  DESC

  ensurable

  newparam(:name, :namevar => true) do
    desc <<-DESC
    The name parameter is also used as the S3 URL location for this S3 key.  This means that s3_key names must follow
    the URL format s3://[bucket]/the/key/path.txt and only use letters, numbers, periods and hyphens.
    DESC
    validate do |value|
      segments = value.split('/')
      fail("s3_key name needs to begin with 's3://'") unless segments[0] == "s3:" and segments[1].length == 0
      fail("The bucket name '#{segments[2]}' is invalid") unless /^[a-zA-Z0-9.\-_]{1,255}$/ =~ segments[2]
      fail("The keyname name '#{segments[3, segments.length].join('/')}' is invalid") unless /^[a-zA-Z0-9.\-_\/]{1,255}$/ =~ segments[3, segments.length].join('/')
    end
  end

  newproperty(:content) do
    desc <<-DESC
    The content of the S3 key, as stored in S3.
    DESC

  end

  newproperty(:grants, :array_matching => :all) do
    desc <<-DESC
    This property grants access permissions, following the AWS owner, authenticated user, everyone model.
    DESC
    validate do |value|
      #  validate value matches rules.
    end
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:owner) do
    desc <<-DESC
      The AWS account owner of this key. With this property it is possible to grant ownership of this key to another
      AWS account.
    DESC
    validate do |value|
      fail("the owner property should be 'acc|<name>|<id>'") unless value.split('|').length == 3
      fail("the owner property should be 'acc|<name>|<id>'") unless value.split('|')[0] == 'acc'
    end
  end

  newproperty(:metadata) do
    desc <<-DESC
    metadata may contain key/value data pairs containing data relating to this S3 key.
    DESC

  end

end

