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
require 'puppet_x/intechwifi/exceptions'

module PuppetX
  module IntechWIFI
    module AwsCmds
      @vpc_tag_cache = { :key => nil, :value => nil}

      def AwsCmds.clear_vpc_tag_cache(name)
        @vpc_tag_cache = { :key => nil, :value => nil} if @vpc_tag_cache[:key] == name
      end

      def AwsCmds.find_vpc_tag(regions, name, &aws_command)
        #  Typically, a puppet run will only be dealing with the one VPC, but many components
        #  will need to obtain the vpcid from vpc name.  As an optimisation, we cache the last answer.
        #

        result = nil

        result = @vpc_tag_cache[:value] unless @vpc_tag_cache[:key] != name

        if result == nil
          result = AwsCmds.find_tag(regions, "vpc", "Name", "value", name, &aws_command)
          @vpc_tag_cache = { :key => name, :value => result}
        end
        result
      end

      def AwsCmds.find_name_by_id(region, resource_type, id, &aws_command)
        AwsCmds.find_tag([region], resource_type, "Name", "resource-id", id, &aws_command)[:tag]["Value"]
      end

      def AwsCmds.find_id_by_name(region, resource_type, id, &aws_command)
        AwsCmds.find_tag([region], resource_type, "Name", "value", id, &aws_command)[:tag]["ResourceId"]
      end


      def AwsCmds.find_tag(regions, resource_type, key, filter, value, &aws_command)
        tags = []
        region = nil
        regions.each{ |r|
          output = aws_command.call('ec2', 'describe-tags', '--filters', "Name=resource-type,Values=#{resource_type}", "Name=key,Values=#{key}", "Name=#{filter},Values=#{value}", '--region', r)
          JSON.parse(output)["Tags"].each{|t| tags << t; region = r }
        }

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, value if tags.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, value if tags.length > 1

        {:tag => tags[0], :region => region }
      end



    end
  end
end
