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

Puppet::Type.newtype(:lambda) do
  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:region) do
    defaultto 'ap-southeast-2'
  end

  newproperty(:runtime) do
  end

  newproperty(:role) do
    munge do |value|
      value.truncate(64) # Max character length is 64 for iam role names
    end
  end

  newproperty(:handler) do
  end

  newproperty(:s3_bucket) do
  end

  newproperty(:s3_key) do
  end
end