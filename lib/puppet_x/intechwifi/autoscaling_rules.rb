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

require 'json'
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/awscmds'

module PuppetX
  module IntechWIFI
    module Autoscaling_Rules
      def self.is_valid_lc_name?(basename, potential_match)
        !(/^#{basename}_=[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]=$/ =~ potential_match).nil?
      end

      def self.base_lc_name(name)
        result = name
        result = name.slice(0, name.length - 6) if (/_=[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]=$/ =~ name)
      end

      def self.index(name)
        name[-4..-2].split("").map{|c| extract_code_value(c)}.reduce(0){ |memo, v| memo * 62 + v }
      end

      def self.encode_index(value)
        output = []
        while value > 0
          value, m = value.divmod(62)
          output = [ encode_code_value(m) ] << output
        end
        output = ["00", output].flatten.join[-3..-1]
        "_=#{output}="
      end

      def self.extract_code_value letter
        ord = letter.ord - 48
        ord = ord -7 if ord > 9
        ord = ord - 9 if ord > 35
        ord
      end

      def self.encode_code_value value
        output = (value + 48).chr.to_s if value < 10
        output = (value + 55).chr.to_s if value > 9 and value < 37
        output =(value + 61).chr.to_s if value >35 and value < 62
        output
      end

      def self.get_load_balancer( name, region, &aws_command)
        puts "#{name} GETTING LOAD BALANCER"
        args = [
            'autoscaling', 'describe-load-balancer-target-groups',
            '--region', region,
            '--auto-scaling-group-name', name
        ]


        result = JSON.parse(aws_command.call(args.flatten))
        puts "ELB RESULTS #{result}"
        result2 = result["LoadBalancerTargetGroups"]
        puts "ELB RESULTS2 #{result2}"

        raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name if result2.length == 0
        raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, name if result2.length > 1  #  Multiple matches

        shit = result2.map{|data|
          /^arn:aws:elasticloadbalancing:[a-z\-0-9A-Z]+:[0-9]+:targetgroup\/([0-9a-z\-]+)\/[0-9a-f]+$/.match(data['LoadBalancerTargetGroupARN'])[1]
        }[0]
        puts "THE SHIT #{shit}"
      rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
        nil
      end
    end
  end
end
