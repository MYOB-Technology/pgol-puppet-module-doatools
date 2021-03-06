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
    module Logical

      def Logical.logical_true(value)
        result = (value == true or value == :true or value == 'true' or value == :enabled or value == 'enabled' or value == :yes or value == 'yes')
        result
      end

      def Logical.logical_false(value)
        result = (value == false or value == :false or value == 'false' or value == :disabled or value == 'disabled' or value == :no or value == 'no')
        result
      end

      def Logical.logical(value)
        result = nil
        if logical_true(value) then result = 'enabled' end
        if logical_false(value) then result = 'disabled' end
        if result == nil then fail("Value '#{value}' could not be converted into a true/false value") end
        return result
      end

      def Logical.string_true_or_false(value)
        if logical_true(value)
          return 'true'
        end
        if logical_false(value)
          return 'false'
        end
      end


      def Logical.array_of_hashes_equal?(a, b)
        # Some quick answers....
        return true if  a.nil? and b.nil?
        return false if !a.kind_of?(Array) or !b.kind_of?(Array)
        return false if a.length != b.length


        a.all? {|val| b.include? val}
        b.all? {|val| a.include? val}

      end
    end
  end
end
