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

Puppet::Type.newtype(:s3_bucket) do
  ensurable

  newparam(:name, :namevar => true) do
    validate do |value|
      fail("AWS recomend bucket names do not have upper case letters.") unless value.downcase == value
      fail("AWS recomend bucket names do not contain periods.") unless value.index('.').nil?
      fail("Bucket names must be between 3 and 63 characters long.") unless value.length >= 3 and value.length <= 63
      fail("Bucket names must not be a valid IP address.") unless !(/^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}/ =~ value)
    end
  end

  #  read only properties...
  newparam(:region) do
    defaultto 'us-east-1'
    validate do |value|
      regions = PuppetX::IntechWIFI::Constants.Regions
      fail("Unsupported AWS Region #{value} we support the following regions #{regions}") unless regions.include? value
    end
  end


  newproperty(:policy, :array_matching => :all) do
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:grants, :array_matching => :all) do
    validate do |value|
      #  validate value matches rules.
    end
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

  newproperty(:cors, :array_matching => :all) do
    validate do |value|
      #  validate value matches rules.
    end
    def insync?(is)
      is.all?{|v| @should.include? v} and @should.all?{|v| is.include? v}
    end
  end

end
