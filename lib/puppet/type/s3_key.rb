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

  ensurable

  newparam(:name, :namevar => true) do
    validate do |value|
      segments = value.split('/')
      fail("s3_key name needs to begin with 's3://'") unless segments[0] == "s3:" and segments[1].length == 0
      fail("The bucket name '#{segments[2]}' is invalid") unless /^[a-zA-Z0-9.\-_]{1,255}$/ =~ segments[2]
      fail("The keyname name '#{segments[3, segments.length].join('/')}' is invalid") unless /^[a-zA-Z0-9.\-_\/]{1,255}$/ =~ segments[3, segments.length].join('/')
    end
  end

  newproperty(:content) do

  end

  newproperty(:grants, :array_matching => :all) do
    validate do |value|
      #  validate value matches rules.
    end
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:owner) do
    validate do |value|
      fail("the owner property should be 'acc|<name>|<id>'") unless value.split('|').length == 3
      fail("the owner property should be 'acc|<name>|<id>'") unless value.split('|')[0] == 'acc'
    end
  end

end

