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
require 'puppet_x/intechwifi/awscmds'
require 'active_support/core_ext/hash'

module PuppetX
  module IntechWIFI
    module EBS_Volumes
        BASE_DEVICE_NAME = 'xvd'
        EBS_DEVICE_NAME_LETTERS = ('f'..'z').to_a
        DEVICE_NAME = 'DeviceName'
        SNAPSHOT_ID = 'SnapshotId'

        def self.get_disks_block_device_mapping(disks)
            disks.each_with_index.map { |disk, i| { DEVICE_NAME => "#{BASE_DEVICE_NAME}#{EBS_DEVICE_NAME_LETTERS[i]}", 'Ebs' => disk } }
        end

        def self.get_image_block_device_mapping(disks)
            disks.keys.map { |device_name| { DEVICE_NAME => device_name, 'Ebs' => disks[device_name] } }
        end

        def self.merge_block_device_mapping(existing_mappings, configured_mappings)
            (existing_mappings + configured_mappings).group_by { |h| h[DEVICE_NAME] }
                                                     .map { |k,v| v.reduce(:deep_merge) }
        end

        def self.remove_snapshot_encrypted_flag(mappings)
            mappings.map do | mapping |
                (mapping['Ebs'] && mapping['Ebs'].key?(SNAPSHOT_ID)) ? 
                { DEVICE_NAME => mapping[DEVICE_NAME], 'Ebs' => mapping['Ebs'].reject { |key, _val| key == 'Encrypted'} } :
                mapping
            end
        end
    end
  end
end
