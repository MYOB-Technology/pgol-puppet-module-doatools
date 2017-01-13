# Doatools 
## A devops AWS / Puppet toolkit

This puppet module is intended to simplify the process of spinning up
and down AWS application stacks.

###  Supported AWS Network Components

* vpc
* subnet
* internet gateway
* _network access control list_
* _security group_
* _route_table_


###  Supported AWS EC2 Components

* _elastic load balancers_
* _launch_config_
* _autoscaling group_
* _ec2 instance_
* _rds instance_



### Prerequisits
This module is uses the aws command line to probe and change the AWS environment 

---
###  Examples
The simplest viable manifest is just:
```$puppet
require doatools
doatools::network { 'demo_env':
 
}
```
This will ensure that a VPC named demo_env is present, with 3 public subnets,
and the default route table is also called demo_env.




```$puppet
cidr         => "192.168.1.0/24"   # Any valid CIDR range
region       => "us-west-2"        # Create the VPC in the us-west-2 region
availability => [ 'a', 'b', 'c' ]  # Use these availabilty zones
zones        => []                 # Network Zones - defines a network space
                                   # that shares common settings, bit spans
                                   # multiple avaliability zones.
```







  vpc_cidr => "192.168.128.0/24",
  region => "us-east-1",
  environment => ="demonstration",
  availability => [ 'a', 'b', 'c'],
  $zones = [
  {
   label => "p",
    cidr => "192.168.128.0/25",
    public_ip => true,
    availability => [ 'a', 'b', 'c' ],
  },
  {
    label => "",
    cidr => "192.168.128.128/25",
    public_ip => false,
    availability => [ 'a', 'c' ],
  }]
)
