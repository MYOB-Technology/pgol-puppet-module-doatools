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

        def self.get_image_disks_from_block_device_mapping(block_device_mapping, ami_image_mapping)
          block_device_mapping.select { |mapping| get_ami_image_device_names(ami_image_mapping).include?(mapping[DEVICE_NAME]) }
                              .map { |mapping| { mapping[DEVICE_NAME] => mapping['Ebs'] } }
                              .reduce({}){ | hash, kv| hash.merge(kv) }
        end

        def self.get_extra_disks_from_block_device_mapping(block_device_mapping, ami_image_mapping)
          block_device_mapping.reject { |mapping| get_ami_image_device_names(ami_image_mapping).include?(mapping[DEVICE_NAME]) }
                              .map { |mapping| mapping['Ebs'] }
        end

        def self.get_extra_disks_from_block_device_hash(block_device_mapping, ami_image_hash)
          block_device_mapping.select { | mapping|
            !ami_image_hash.has_key?(mapping[DEVICE_NAME])
          }.map { |mapping| mapping['Ebs'] }
        end


        def self.get_ami_image_device_names(ami_image_mapping)
          ami_image_device_names = ami_image_mapping.map { |mapping| mapping[DEVICE_NAME] }
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
