require 'json'
require 'puppet_x/intechwifi/exceptions'

Puppet::Functions.create_function('find_rds_endpoint') do
  def find_rds_endpoint(region, rds)
    args = "aws rds describe-db-instances --region #{region} --db-instance-identifier #{rds}"

    result = JSON.parse(%x(#{args}))["DBInstances"]

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, rds if result.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, rds if result.length > 1

    {
        :address => result[0]["Endpoint"]["Address"],
        :port    => result[0]["Endpoint"]["Port"]
    }
  rescue => e
    warn("find_rds_endpoint caught an exception #{e}")
    fail("Could not find the RDS endpoint for database instance '#{rds}' in region '#{region}'")
  end

end