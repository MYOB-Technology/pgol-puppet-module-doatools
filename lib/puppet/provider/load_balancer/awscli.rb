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
require 'puppet_x/intechwifi/constants'
require 'puppet_x/intechwifi/logical'
require 'puppet_x/intechwifi/awscmds'
require 'puppet_x/intechwifi/exceptions'

Puppet::Type.type(:load_balancer).provide(:awscli) do
  commands :awscli => "aws"

  def create
    args = [
        'elbv2', 'create-load-balancer',
        '--region', @resource[:region],
        '--name', @resource[:name],
        '--subnets', resource[:subnets].map{|subnet| PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@resource[:region], 'subnet', subnet){|*arg| awscli(*arg)} }
    ]

    awscli(args.flatten)

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]
    @property_hash[:subnets] = @resource[:subnets]

  end

  def destroy
    args = [
        'elbv2', 'delete-load-balancer',
        '--region', @resource[:region],
        '--load-balancer-arn', @arn
    ]

    awscli(args.flatten)

  end

  def exists?
    #
    #  If the puppet manifest is delcaring the existance of a VPC then we know its region.
    #
    regions = [ resource[:region] ] if resource[:region]

    #
    #  If we don't know the region, then we have to search each region in turn.
    #
    regions = PuppetX::IntechWIFI::Constants.Regions if !resource[:region]

    debug("searching regions=#{regions} for load_balancer=#{resource[:name]}\n")


    search_results = PuppetX::IntechWIFI::AwsCmds.find_load_balancer_by_name(regions, resource[:name]) do | *arg |
      awscli(*arg)
    end

    @property_hash[:region] = search_results[:region]
    @property_hash[:name] = resource[:name]

    data = search_results[:data][0]
    @arn = data["LoadBalancerArn"]
    @property_hash[:subnets] = data["AvailabilityZones"].map{|subnet| PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'subnet', subnet["SubnetId"]){|*arg| awscli(*arg)} }
    @property_hash[:listeners] = JSON.parse(awscli('elbv2', 'describe-listeners', '--region', @property_hash[:region], '--load-balancer-arn', @arn))["Listeners"].map do |x|
      "#{x["Protocol"].downcase}://#{target_from_arn x["DefaultActions"][0]["TargetGroupArn"]}:#{x["Port"]}#{x["Certificates"].nil? ? "" : ("?certificate=" + x["Certificates"][0]["CertificateArn"])}"
    end
    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def flush
    if @property_flush and @property_flush.length > 0
      set_subnets(@property_flush[:subnets]) if !@property_flush[:subnets].nil?
      #@property_flush[:listeners].select{|x| !@property_hash[:listeners].include? x}.each{|x| create_listener(x)} if !@property_flush[:listeners].nil?
      @property_flush[:listeners].select{|x| !@property_hash[:listeners].include?(x)}.each{|x| create_listener(x)} if !@property_flush[:listeners].nil?
      @property_hash[:listeners].select{|x| !@property_flush[:listeners].include?(x)}.each{|x| destroy_listener(x)} if !@property_flush[:listeners].nil?
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def set_subnets(subnets)
    args = [
        'elbv2', 'set-subnets',
        '--region', @property_hash[:region],
        '--load-balancer-arn', @arn,
        '--subnets', subnets.map{|subnet| PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'subnet', subnet){|*arg| awscli(*arg)} }
    ]
    awscli(args.flatten)

  end

  def create_listener(source)
    match = /^(http[s]?):\/\/([a-z1-9\_]{3,255}):([0-9]{2,4})/.match(source)
    proto = match[1]
    target = match[2]
    port = match[3]

    match_cert = /^http[s]?:\/\/[a-z1-9\_]{3,255}:[0-9]{2,4}\?certificate=(.+)$/.match(source)
    certificate = match_cert.nil? ? nil : match_cert[1]

    args = [
        'elbv2', 'create-listener',
        '--region', @property_hash[:region],
        '--load-balancer-arn', @arn,
        '--protocol', proto.upcase,
        '--port', port,
        '--default-actions', "Type=forward,TargetGroupArn=#{find_target_by_name(@arn, target)}"
    ]
    args << ['--certificates', "CertificateArn=#{certificate}"] if proto=="https" and !certificate.nil?
    awscli(args.flatten)

  end

  def destroy_listener(source)
    match = /^http[s]?:\/\/([a-z1-9\_]{3,255}):[0-9]{2,4}/.match(source)
    target = match[1]

    listener_arn = JSON.parse(awscli('elbv2', 'describe-listeners', '--region', @property_hash[:region], '--load-balancer-arn', @arn))["Listeners"].select{ |x|
      target_from_arn(x["DefaultActions"][0]["TargetGroupArn"]) == target
    }.map{|x| x["ListenerArn"]}[0]

    args = [
        'elbv2', 'delete-listener',
        '--region', @property_hash[:region],
        '--listener-arn', listener_arn,
    ]
    awscli(args.flatten)

  end

  def target_from_arn(target_arn)
    /^arn:aws:elasticloadbalancing:[a-z_\-0-9]+:[0-9]{12}:targetgroup\/([a-z_\-0-9]+)\/[0-9a-f]{16}$/.match(target_arn)[1]
  end


  def find_target_by_name(load_balancer_arn, name)
    args = [
        'elbv2', 'describe-target-groups',
        '--region', @property_hash[:region],
#        '--load-balancer-arn', load_balancer_arn,
        '--names', name
    ]
    JSON.parse(awscli(args.flatten))["TargetGroups"][0]["TargetGroupArn"]
  end

  mk_resource_methods

  def region=(value)
    @property_flush[:region] = value
  end

  def subnets=(value)
    @property_flush[:subnets] = value
  end

  def listeners=(value)
    @property_flush[:listeners] = value
  end

end