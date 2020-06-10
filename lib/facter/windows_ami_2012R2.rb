require 'puppet_x/intechwifi/constants'

Facter.add('windows_ami_2012R2') do
    setcode do

      if region = ENV['REGION']
        regions = [region]
      else
        regions = PuppetX::IntechWIFI::Constants.Regions
      end

      ami_by_region = {}
      threads = []  

      regions.each do |r|
        threads << Thread.new { Thread.current[:output] = describe_windows_image_for_region(r) }
      end

      threads.each do |t|
        t.join
        ami_by_region = ami_by_region.merge(t[:output])
      end
      ami_by_region
      
    end

    def describe_windows_image_for_region(region)
      begin
        response = Facter::Core::Execution.execute("aws ec2 describe-images --owners amazon --region #{region} --filters 'Name=name,Values=Windows_Server-2012-R2_RTM-English-64Bit-Base*' --query 'sort_by(Images, &CreationDate)[]'")
        latest_image = JSON.parse(response)[-1]["ImageId"]
        return {region => latest_image}           
      rescue StandardError => e
        return {}
      end
    end
  end