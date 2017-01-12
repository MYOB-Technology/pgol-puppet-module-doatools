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

module PuppetX
  module IntechWIFI
    module Exceptions
      class IntechWIFIError < RuntimeError
      end


      class NotFoundError < StandardError
        def initialize(name)
          super("#{name} was not found.")
        end
      end

      class MultipleMatchesError < NotFoundError
        def initialize(vpc)
          super("Multiple possible Vpc #{vpc} were found.  Not safe to continue")
        end
      end

      class VpcNotFoundError  <  StandardError
        def initialize(vpc_name)
          super("Vpc #{vpc_name} was not found.")
        end
      end

      class VpcNotNamedError < StandardError
        def initialize(name)
          super("Vpc-id #{name} did not have a name tag.")
        end
      end

    end
  end
end
