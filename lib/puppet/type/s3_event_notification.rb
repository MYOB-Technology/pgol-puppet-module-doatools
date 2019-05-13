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

Puppet::Type.newtype(:s3_event_notification) do
  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:region) do
    defaultto 'ap-southeast-2'
  end

  newproperty(:bucket) do
  end

  newproperty(:endpoint) do
  end

  newproperty(:endpoint_type) do
    validate do |value|
      types = PuppetX::IntechWIFI::Constants.notification_types
      fail("Unsupported Notification Type #{value} we support the following types #{types}") unless types.include? value
    end
  end

  newproperty(:events, :array_matching => :all) do
  end

  newproperty(:key_prefixs, :array_matching => :all) do
    defaultto []
  end

  newproperty(:key_suffixs, :array_matching => :all) do
    defaultto []
  end
end