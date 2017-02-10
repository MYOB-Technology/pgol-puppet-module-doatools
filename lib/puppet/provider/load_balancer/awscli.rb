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

    args << [ '--security-groups', resource[:security_groups].map{|x| PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@resource[:region], 'security-group', x){|*arg| awscli(*arg)}  } ] if !@resource[:security_groups].nil? and @resource[:security_groups].length > 0

    @arn = JSON.parse(awscli(args.flatten))["LoadBalancers"][0]["LoadBalancerArn"]

    @property_hash[:name] = @resource[:name]
    @property_hash[:region] = @resource[:region]
    @property_hash[:subnets] = @resource[:subnets]

    @resource[:targets].each{|x| create_target(@resource[:region], x)} if !@resource[:targets].nil?
    @property_hash[:targets] = @resource[:targets] if !@resource[:targets].nil?

    @resource[:listeners].each{|x| create_listener(x)} if !@resource[:listeners].nil?
    @property_hash[:listeners] = @resource[:listeners] if !@resource[:listeners].nil?



  end

  def destroy
    #  We need to remove the listeners first.
    @property_hash[:listeners].each{|x| destroy_listener(x)} if !@property_hash[:listeners].nil?

    #  Then the targets
    @property_hash[:targets].each{|x| destroy_target(@property_hash[:region], x)} if !@property_hash[:targets].nil?

    #  and then we can delete the load balancer.
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
    @property_hash[:targets] = list_elb_targets()

    @property_hash[:security_groups] = data["SecurityGroups"].map{|sg| PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'security-group', sg){| *arg | awscli(*arg)} }

    true

  rescue PuppetX::IntechWIFI::Exceptions::NotFoundError => e
    debug(e)
    false

  rescue PuppetX::IntechWIFI::Exceptions::MultipleMatchesError => e
    fail(e)
    false
  end

  def flush
    print "called flush\n"

    if @property_flush and @property_flush.length > 0
      set_subnets(@property_flush[:subnets]) if !@property_flush[:subnets].nil?
      @property_flush[:targets].select{|x| !@property_hash[:targets].any?{|y| same_target_name(x, y)}}.each{|x| create_target(@property_hash[:region], x)} if !@property_flush[:targets].nil?
      @property_flush[:listeners].select{|x| !@property_hash[:listeners].include?(x)}.each{|x| create_listener(x)} if !@property_flush[:listeners].nil?
      @property_hash[:listeners].select{|x| !@property_flush[:listeners].include?(x)}.each{|x| destroy_listener(x)} if !@property_flush[:listeners].nil?
      @property_hash[:targets].select{|x| !@property_flush[:targets].any?{|y| same_target_name(x, y)}}.each{|x| destroy_target(@property_hash[:region], x)} if !@property_flush[:targets].nil?

      @property_flush[:targets].select{|x| @property_hash[:targets].any?{|y| same_target_name(x, y) and x != y } }.each{|x| modify_target(@property_hash[:region], x)} if !@property_flush[:targets].nil?

      awscli([
          'elbv2', 'set-security-groups',
          '--region', @property_hash[:region],
          '--load-balancer-arn', @arn,
          '--security-groups', @property_flush[:security_groups].map{|x| PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@resource[:region], 'security-group', x){|*arg| awscli(*arg)}  }
      ].flatten) if !@property_flush[:security_groups].nil?

    end
    print "completed flush\n"
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
        '--default-actions', "Type=forward,TargetGroupArn=#{find_target_by_name(target)}"
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

  def create_target(region, source)
    args = [
        'elbv2', 'create-target-group',
        '--region', region,
        '--name', source["name"],
        '--protocol', 'HTTP',
        '--port', source["port"],
        '--vpc-id', PuppetX::IntechWIFI::AwsCmds.find_id_by_name(@property_hash[:region], 'vpc', source["vpc"]){|*arg| awscli(*arg)},
        '--health-check-protocol', 'HTTP',
        '--health-check-port', source["port"],
    ]

    args << ['--health-check-path', source["path"] ]   if !source["path"].nil?
    args << ['--health-check-interval-seconds', source["check_interval"] ]   if !source["check_interval"].nil?
    args << ['--health-check-timeout-seconds', source["timeout"] ]   if !source["timeout"].nil?
    args << ['--healthy-threshold-count', source["healthy"] ]   if !source["healthy"].nil?
    args << ['--unhealthy-threshold-count', source["failed"] ]   if !source["failed"].nil?
    args << ['--health-check-path', source["path"] ]   if !source["path"].nil?

    awscli(args.flatten)

  end

  def modify_target(region, source)
    args = [
        'elbv2', 'describe-target-groups',
        '--region', region,
        '--name', source["name"]
    ]
    arns = JSON.parse(awscli(args.flatten))["TargetGroups"].select{|x| x["TargetGroupName"] == source["name"]}.map{|x| x["TargetGroupArn"]}.flatten

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, source["name"] if arns.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, source["name"] if arns.length > 1


    args = [
        'elbv2', 'modify-target-group',
        '--region', region,
        '--target-group-arn', arns[0]
    ]

    args << ['--health-check-path', source["path"] ]   if !source["path"].nil?
    args << ['--health-check-interval-seconds', source["check_interval"] ]   if !source["check_interval"].nil?
    args << ['--health-check-timeout-seconds', source["timeout"] ]   if !source["timeout"].nil?
    args << ['--healthy-threshold-count', source["healthy"] ]   if !source["healthy"].nil?
    args << ['--unhealthy-threshold-count', source["failed"] ]   if !source["failed"].nil?
    args << ['--health-check-path', source["path"] ]   if !source["path"].nil?

    awscli(args.flatten)

  end


  def destroy_target(region, source)
    args = [
        'elbv2', 'describe-target-groups',
        '--region', region,
        '--name', source["name"]
    ]
    arns = JSON.parse(awscli(args.flatten))["TargetGroups"].select{|x| x["TargetGroupName"] == source["name"]}.map{|x| x["TargetGroupArn"]}.flatten

    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, source["name"] if arns.length == 0
    raise PuppetX::IntechWIFI::Exceptions::MultipleMatchesError, source["name"] if arns.length > 1

    args = [
        'elbv2', 'delete-target-group',
        '--region', region,
        '--target-group-arn', arns[0]
    ]
    awscli(args.flatten)

  end

  def list_elb_targets()
    JSON.parse(awscli('elbv2', 'describe-target-groups', '--region', @property_hash[:region], '--load-balancer-arn', @arn))["TargetGroups"].map do |x|
      {
          "name" => x["TargetGroupName"],
          "port" => x["Port"],
          "check_interval" => x["HealthCheckIntervalSeconds"],
          "timeout" => x["HealthCheckTimeoutSeconds"],
          "healthy" => x["HealthyThresholdCount"],
          "failed" => x["UnhealthyThresholdCount"],
          "vpc" => PuppetX::IntechWIFI::AwsCmds.find_name_by_id(@property_hash[:region], 'vpc', x["VpcId"]){|*arg| awscli(*arg)}
      }
    end

  rescue Puppet::ExecutionFailure => e
    []
  end



  def target_from_arn(target_arn)
    /^arn:aws:elasticloadbalancing:[a-z_\-0-9]+:[0-9]{12}:targetgroup\/([a-z_\-0-9]+)\/[0-9a-f]{16}$/.match(target_arn)[1]
  end


  def find_target_by_name(name)
    args = [
        'elbv2', 'describe-target-groups',
        '--region', @property_hash[:region],
        '--names', name
    ]
    JSON.parse(awscli(args.flatten))["TargetGroups"][0]["TargetGroupArn"]

  rescue Puppet::ExecutionFailure => e
    raise PuppetX::IntechWIFI::Exceptions::NotFoundError, name
  end

  def same_target_name(a, b)
    result = false
    result = true if !a.nil? and !b.nil? and a["name"] == b["name"]
    result = true if result == false and a == b  # if they are both nil.

    result
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

  def targets=(value)
    @property_flush[:targets] = value
  end

  def security_groups=(value)
    @property_flush[:security_groups] = value
  end

end