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
        REJECT_KEYS = ['DeviceName', 'Source']
        SNAPSHOT_ID = 'SnapshotId'

        def self.get_block_device_mapping(volumes)
            generic = volumes.select { |vol| vol['Source'].nil? || vol['Source'].empty? }
            non_generic = volumes.reject { |vol| vol['Source'].nil? || vol['Source'].empty? }
            ami_volumes = non_generic.select { |vol| vol['Source']['Ami'] }
                                     .map { |vol| { 'DeviceName' => vol['Source']['Ami'], 'Ebs' => vol.reject { |key, _value| REJECT_KEYS.include? key } } }

            generic_and_snapshot_vols = non_generic.select{ |vol| vol['Source']['Snapshot'] }
                                                   .each{ |vol| vol[SNAPSHOT_ID] = vol['Source']['Snapshot']}
                                                   .concat(generic)
                                                   .each_with_index.map { |vol, i| { 'DeviceName' => "#{BASE_DEVICE_NAME}#{EBS_DEVICE_NAME_LETTERS[i]}", 'Ebs' => vol.reject { |key, _val| REJECT_KEYS.include? key } } }

            return ami_volumes.concat(generic_and_snapshot_vols)
        end

        def self.merge_block_device_mapping(existing_mappings, configured_mappings)
            (existing_mappings + configured_mappings).group_by { |h| h['DeviceName'] }
                                                     .map { |k,v| v.reduce(:deep_merge) }
        end

        def self.remove_snapshot_encrypted_flag(mappings)
            mappings.map do | mapping |
                (mapping['Ebs'] && mapping['Ebs'].key?(SNAPSHOT_ID)) ? 
                { 'DeviceName' => mapping['DeviceName'], 'Ebs' => mapping['Ebs'].reject { |key, _val| key == 'Encrypted'} } :
                mapping
            end
        end
    end
  end
end
