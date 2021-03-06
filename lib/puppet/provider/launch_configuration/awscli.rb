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

require 'puppet'
require 'json'
require 'tempfile'
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/awscmds'
require 'puppet_x/intechwifi/exceptions'
require 'puppet_x/intechwifi/ebs_volumes'

Puppet::Type.type(:launch_configuration).provide(:awscli) do
  commands :awscli => "aws"

  def create
    notice("called launch_configuration.create")

    #  Since we cannot update properties after creating a launch configuration, we actually create the new launch configuration
    #  when we flush the properties.
    @property_hash[:index] = 0
    @property_hash[:name] = resource[:name]
    @property_hash[:region] = resource[:region]
    self.image = resource[:image]
    self.instance_type = resource[:instance_type]
    self.security_groups = resource[:security_groups]
    self.userdata = resource[:userdata]
    self.ssh_key_name = resource[:ssh_key_name]
    self.iam_instance_profile = resource[:iam_instance_profile]
    self.public_ip = resource[:public_ip]
    #  Use the aws details as the default, and the image disks data as the overrides.

    begin
      self.image_disks = PuppetX::IntechWIFI::AwsCmds.find_disks_by_ami(resource[:region], resource[:image]) {| *arg | awscli(*arg) }

    rescue PuppetX::IntechWIFI::Exceptions::NotFoundError
      fail("the AMI '#{resource[:image]}' is not known by AWS.  Has it been deleted? or retired?")
    end
    self.extra_disks = resource[:extra_disks]


    @property_hash[:region] = resource[:region]

  end

  def destroy
    lcs = JSON.parse(awscli('autoscaling', 'describe-launch-configurations', '--region', @property_hash[:region]))["LaunchConfigurations"].select{|l|
      PuppetX::IntechWIFI::Autoscaling_Rules.is_valid_lc_name?(name, l['LaunchConfigurationName'] )
    }.reduce([]){|memo, lc| memo << lc }

    lcs.each{|lc| awscli("autoscaling", "delete-launch-configuration", '--region', @property_hash[:region], "--launch-configuration-name", lc['LaunchConfigurationName']) }
  end

  def exists?
    ##############################################################################################################################
    #  This aws resource does not allow modification in place so if there are any property changed, we must create a new one
    #  Consequently, any properties set outside of puppet will not be copied across if changes occur
    ##############################################################################################################################
    debug("running launchconfig.awscli.exists?")

    #
    #  If the puppet manifest is delcaring the existance of a subnet then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]
    debug("searching regions=#{regions} for launch_configuration=#{resource[:name]}\n")

    #  launch configurations cannot be modified in place. When we change properties we have to create a new one. to handle this
    #  we add a sequential 6 digit number on the end of the launch configuration.

    launch_config = PuppetX::IntechWIFI::AwsCmds.find_launch_configuration_by_name(regions,resource[:name]) {| *arg | awscli(*arg) }
    debug("Found the LaunchConfiguration '#{launch_config["LaunchConfigurationName"]}'.")

    @property_hash[:ensure] = :present
    #!TODO: Region should really be extracted from the ARN value.
    @property_hash[:region] = resource[:region]
    @property_hash[:name] = resource[:name]

    @property_hash[:index] = PuppetX::IntechWIFI::Autoscaling_Rules.index(launch_config["LaunchConfigurationName"])
    debug("Found the LaunchConfiguration Index is #{@property_hash[:index]}.")
    @property_hash[:image] = launch_config["ImageId"]
    @property_hash[:instance_type] = launch_config["InstanceType"]
    @property_hash[:security_groups] = launch_config["SecurityGroups"].map {|id|
      PuppetX::IntechWIFI::AwsCmds.find_name_or_id_by_id(@property_hash[:region], 'security-group', id ){| *arg | awscli(*arg) }
    }

    @property_hash[:userdata] = Base64.decode64(launch_config["UserData"])
    @property_hash[:ssh_key_name] = launch_config["KeyName"]
    @property_hash[:iam_instance_profile] = launch_config["IamInstanceProfile"]
    @property_hash[:public_ip] = PuppetX::IntechWIFI::Logical.logical(launch_config["AssociatePublicIpAddress"]) if launch_config.has_key?("AssociatePublicIpAddress")


    #  Get the block devices in the current launch config.
    lc_block_device_hash = get_block_device_mapping_as_hash(launch_config['BlockDeviceMappings'])

    #  Get the block devices in the  current launch config ami.
    ami_block_device_hash = PuppetX::IntechWIFI::AwsCmds.find_disks_by_ami(@property_hash[:region], @property_hash[:image]) {| *arg | awscli(*arg) }

    lc_block_device_hash.select { |device, settings| ami_block_device_hash.has_key? device }

    ami_block_device_mapping = get_ami_block_device_mapping(@property_hash[:region], @property_hash[:image])
    block_device_mapping = launch_config['BlockDeviceMappings']

    #  Image disks only contain disk info that are part of the original ami
    @property_hash[:image_disks] = lc_block_device_hash.select { |device, settings| ami_block_device_hash.has_key? device }

    #  Extra disks only contain disk info that is not part of the original ami
    @property_hash[:extra_disks] = lc_block_device_hash.select { |device, settings| !ami_block_device_hash.has_key? device }.map{ | key, value| value }
    
    debug("Successfully exiting launchconfig.awscli.exists?")

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false

  end

  def get_ami_block_device_mapping(region, image)
    images = JSON.parse(awscli([
      'ec2',
      'describe-images',
      '--region', region,
      '--image-ids', image
    ]))['Images']
    raise "AWS AMI #{image} is not available. This AMI has likely been deleted by Amazon and replaced with an upgraded AMI. Update hiera to use the upgraded AMI" if images.first.nil?
    images.first['BlockDeviceMappings']
      .select { |mapping| mapping.key? 'Ebs' }
  end

  def merge_ami_hash_and_imagedisks(ami_hash, image_disk_definition)
    #  we may have different device names...

    device_ami = ami_hash.keys[0]
    device_def = image_disk_definition.keys[0]

    merged_hash = {
      device_ami => ami_hash[device_ami].merge(image_disk_definition[device_def])
    }

    # Ensuring we use the snapshotId of the AMI being used (and not the snapshot of the old AMI)
    merged_hash[device_ami]["SnapshotId"] = ami_hash[device_ami]["SnapshotId"]

    return merged_hash
  end

  def get_block_device_mapping_as_hash(bdm)
    bdm.select{ |ami|
      ami.key?('Ebs')
    }.map{ |ami|
      {
        ami["DeviceName"] => ami["Ebs"]
      }
    }.reduce({}) { |memo, data| memo.merge(data) }
  end


  def flush
    if @property_flush and @property_flush.length > 0
      debug("Flushing new property values to launch configuration")
      # We need to create a new launch configuration here every time there is a property change
      @property_flush[:index] = @property_hash[:index] + 1
      new_name = [@property_hash[:name], PuppetX::IntechWIFI::Autoscaling_Rules.encode_index(@property_flush[:index])].join

      userdata_temp_file = nil

      args = [
          "autoscaling",
          "create-launch-configuration",
          "--region", value(:region),
          "--launch-configuration-name", new_name,
          "--image-id", value(:image),
          "--instance-type", value(:instance_type)
      ]

      #  Add in security groups
      if (value(:security_groups).nil? == false) and (value(:security_groups).length > 0)
        args << [
            "--security-groups",
            value(:security_groups).map{|sg|
              PuppetX::IntechWIFI::AwsCmds.find_id_by_name(value(:region), 'security-group', sg){| *arg | awscli(*arg) }
            }
        ]
      end

      if (value(:userdata).nil? == false) and (value(:userdata).length > 0)
        userdata_temp_file = Tempfile.new('userdata')
        userdata_temp_file.write(value(:userdata))
        userdata_temp_file.close

        args << [
            "--user-data", "file://#{userdata_temp_file.path}"
        ]
      end

      if (value(:ssh_key_name).nil? == false) and (value(:ssh_key_name).length > 0)
        args << [
            "--key-name", "#{value(:ssh_key_name)}"
        ]
      end

      if (value(:iam_instance_profile).nil? == false) and (value(:iam_instance_profile).length > 0)
        args << [
            "--iam-instance-profile", value(:iam_instance_profile)
        ]
      end

      args << [ '--associate-public-ip-address'] if PuppetX::IntechWIFI::Logical.logical_true(value(:public_ip))
      args << [ '--no-associate-public-ip-address'] if PuppetX::IntechWIFI::Logical.logical_false(value(:public_ip))

      disks_for_ami = PuppetX::IntechWIFI::AwsCmds.find_disks_by_ami(value(:region), value(:image)) {| *arg | awscli(*arg) }

      #  Get the block devices in the  current launch config ami.
      ami_block_device_hash = merge_ami_hash_and_imagedisks(
          disks_for_ami,
          value(:image_disks)
      )
      debug("creating using ami_block_device_hash=#{ami_block_device_hash}")

      if( value(:extra_disks).nil? )
        extra_disks = []
      else
        extra_disks = value(:extra_disks)
      end

      extra_disk_hash = PuppetX::IntechWIFI::EBS_Volumes.get_disks_block_device_hash(extra_disks)
      
      all_disk_hash = ami_block_device_hash.merge(extra_disk_hash)

      args << ["--block-device-mappings", PuppetX::IntechWIFI::EBS_Volumes.get_image_block_device_mapping_from_hash(all_disk_hash).to_json]

      #  Ensure we have a flat array...
      args.flatten

      #  Create the new launch_configuration
      awscli(args)

      userdata_temp_file.unlink if !userdata_temp_file.nil?

      lcs = JSON.parse(awscli('autoscaling', 'describe-launch-configurations', '--region', @property_hash[:region]))["LaunchConfigurations"].select{|l|
        PuppetX::IntechWIFI::Autoscaling_Rules.is_valid_lc_name?(name, l['LaunchConfigurationName'] ) }.map{|l| l['LaunchConfigurationName']}.sort

      if lcs.length > 5
        lcs.slice(0, lcs.length - 5).each{|lc|
          awscli("autoscaling", "delete-launch-configuration", '--region', value(:region), "--launch-configuration-name", lc)
        }
      end

    end
  end

  def value key
    
    return resource[key] 

  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def region=(value)
    @property_flush[:region] = value
  end

  def instance_type=(value)
    @property_flush[:instance_type] = value
  end

  def image=(value)
    @property_flush[:image] = value
  end

  def security_groups=(value)
    @property_flush[:security_groups] = value
  end

  def userdata=(value)
    @property_flush[:userdata] = value
  end

  def ssh_key_name=(value)
    @property_flush[:ssh_key_name] = value
  end

  def keep_versions=(value)
    @property_flush[:keep_versions] = value
  end

  def iam_instance_profile=(value)
    @property_flush[:iam_instance_profile] = value
  end

  def public_ip=(value)
    @property_flush[:public_ip] = value
  end

  def image_disks=(value)
    @property_flush[:image_disks] = value
  end

  def extra_disks=(value)
    @property_flush[:extra_disks] = value
  end

end