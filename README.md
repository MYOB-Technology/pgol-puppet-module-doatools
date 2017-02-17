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
This module is uses the aws command line to probe and change the AWS environment. written and tested using AWS 1.11.45, other versions may work.

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
require doatools
doatools::network { 'demo_env': 
  cidr         => "192.168.1.0/24"   # Any valid CIDR range
  region       => "us-west-2"        # Create the VPC in the us-west-2 region
  availability => [ 'a', 'b', 'c' ]  # Use these availabilty zones
  zones        => []                 # Network Zones - defines a network space
}                                    # that shares common settings, bit spans
                                     # multiple avaliability zones.
```


This more complex example creates a single VPC with 5 subnets.


```
require doatools
doatools::network { 'demo_env': 
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
}
```

An example that creates servers, load balancers and a database would look more like this:

```
require doatools
doatools::network{ 'test':
  region => 'us-west-2'
} -> doatools::role{ 'test':
  region => 'us-west-2',
  image => 'ami-f173cc91',
  desired => 2,
  min => 0,
  max => 4,
  listeners => [
    'http',
    'arn:aws:acm:us-west-2:309595426446:certificate/29aab77f-898b-4188-a37b-945b81d4cc07'
  ],
  target => {
    name => 'mytest2',
    port => 80,
    check_interval => 30,
    timeout => 10,
    healthy => 3,
    failed => 2,
  },
}
```
