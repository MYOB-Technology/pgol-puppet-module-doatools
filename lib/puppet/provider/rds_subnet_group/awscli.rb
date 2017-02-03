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

Puppet::Type.type(:rds_subnet_group).provide(:awscli) do
  desc "Using the aws command line python application to implement changes"
  commands :awscli => "aws"

  def create

  end

  def destroy

  end

  def exists?

  end

  def flush

  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def vpc=(value)
    @property_flush[:vpc] = value
  end

  def region=(value)
    @property_flush[:region] = value
  end

  def subnets=(value)
    @property_flush[:subnets] = value
  end



end
