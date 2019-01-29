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

module PuppetX
  module IntechWIFI
    module Tags_Property
      def self.validate_value(value)
        fail('The tags property should be a hash of tags and values') if !value.is_a?(Hash)
        fail('We can only support 50 tags') if value.keys.length > 50
        # We block lowercase 'name' as well to avoid confusion later.
        fail('Puppet already uses the tag "Name", it cannot be used inside the tags property') if value.keys.map{|x| x.downcase }.include? 'name'
      end

      def self.insync?(is, should)
        is.class == should.class and
            (!is.is_a?(Hash) or (
              is.keys.all?{|x| should.keys.include? x} and
                  should.keys.all?{|x| is.keys.include? x} and
                  is.keys.all?{|x| insync?(is[x], should[x])})
            ) and
            (!is.is_a?(Array) or (is.all?{|x| should.include? x} and should.all?{|x| is.include? x}))
      end

      def self.parse_tags(tags)
        tags.select{|x| x["Key"].downcase != 'name'}.reduce({}) do |h, x|
          value = x["Value"]

          begin
            value = JSON.parse(value)
          rescue StandardError
          end

          h[x["Key"]] = value

          h
        end
      end


      def self.update_tags(region, resource_id, current, desired, &aws_command)
        add = desired.keys.select{|x| !current.keys.include?(x) or desired[x] != current[x]}.map{|x| [x, desired[x]] }
        del = current.keys.select{|x| !desired.keys.include?(x) or desired[x] != current[x]}

        delete_tags(region, resource_id, del, &aws_command) if del.length > 0
        set_tags(region, resource_id, add, &aws_command) if add.length > 0
      end

      def self.set_tags(region, resource_id, tags, &aws_command)
        args = [
            'ec2', 'create-tags', '--region', region,
            '--resources', resource_id,
            '--tags'
        ]

        args << tags.map{|x| "Key=#{x[0]},Value='#{x[1].is_a?(String) ? x[1] : x[1].to_json}'"}
        aws_command.call(args.flatten)

      end

      def self.delete_tags(region, resource_id, tags, &aws_command)
        args = [
            'ec2', 'delete-tags', '--region', region,
            '--resources', resource_id,
            '--tags'
        ]

        args << tags.map{|x| "Key=#{x}"}

        aws_command.call(args.flatten)

      end


    end
  end
end

