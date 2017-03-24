require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/network_rules'

Puppet::Functions.create_function('format_zone_label') do
  def format_zone_label(specification, vpc, az, index)
    sprintf(specification, {:vpc => vpc, :az => az, :index => index})
  end
end
