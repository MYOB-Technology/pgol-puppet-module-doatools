require 'puppet_x/intechwifi/rds'

Puppet::Functions.create_function('find_rds_endpoint') do
  commands :awscli => "aws"
  def find_rds_endpoint(region, rds)
    PuppetX::IntechWIFI::RDS.find_endpoint(region, rds) { |*arg| awscli(*arg)}
  rescue
    fail("Could not find the RDS endpoint for database instance '#{rds}' in region '#{region}'")
  end

end