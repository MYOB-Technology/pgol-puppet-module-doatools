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
    module S3

      def S3.user_group_to_uri(ug)
        case ug
          when :authenticated
            'http://acs.amazonaws.com/groups/global/AuthenticatedUsers'
          when :public
            'http://acs.amazonaws.com/groups/global/AllUsers'
          when :log_delivery
            'http://acs.amazonaws.com/groups/s3/LogDelivery'
          else
            raise PuppetX::IntechWIFI::Exceptions::NotFoundError ug.to_s
        end
      end

      def S3.uri_to_user_group(uri)
        case uri
          when 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers'
            :authenticated
          when 'http://acs.amazonaws.com/groups/global/AllUsers'
            :public
          when 'http://acs.amazonaws.com/groups/s3/LogDelivery'
            :log_delivery
          else
            raise PuppetX::IntechWIFI::Exceptions::NotFoundError uri
        end
      end

      def S3.grant_json_to_property(source)
        case source['Grantee']['Type']
          when 'CanonicalUser'
            "acc|#{source['Grantee']['DisplayName']}|#{source['Grantee']['ID']}|#{source['Permission']}"
          when 'Group'
            "grp|#{source['URI']}|#{source['Permission']}"
        end
      end

      def S3.grant_property_to_hash(source)
        s = source.split('|')
        {
            :Grantee => case s[0]
                          when 'acc'
                            {
                                :Type => "CanonicalUser",
                                :DisplayName => s[1],
                                :ID => s[2]
                            }
                          when 'grp'
                            {
                                :Type => "Group",
                                :URI => s[1]
                            }
                        end,
            :Permission => s[-1]
        }
      end

      def S3.owner_to_hash(source)
        s = source.split('|')
        {
            :DisplayName => s[1],
            :ID => s[2]
        }
      end

      def S3.owner_to_property(source)
        "acc|#{source['DisplayName']}|#{source['ID']}"
      end

      def S3.name_to_bucket_key_pair(name)
        # we need to check if we have a path on the end...
        append = name[-1] == '/'? "/" : ""
        arr = name.split('/')
        {
            :bucket => arr[2],
            :key => arr[3..arr.length].join("/") + append
        }
      end

      def S3.get_owner_for_bucket(bucket, &aws_command)
        owner_to_property(JSON.parse(aws_command.call('s3api', 'get-bucket-acl', '--bucket', bucket))["Owner"])
      end


    end
  end
end

