# Doatools 
## A devops AWS / Puppet toolkit

This puppet module is intended to simplify the process of spinning up
and down AWS application stacks.

### Supported AWS Network Components

* vpc
* subnet
* internet\_gateway
* security\_group

### Supported AWS EC2 Components

* elastic load balancer
* launch\_config
* autoscaling\_group
* rds

### Supported AWS IAM Components

* iam_role
* iam_policy


### Composite Components

* **network** - a AWS VPC, subnets, route table and internet gateway.
* **role** - An application stack consisting of a launch configuration, autoscaling group and optional load balancers and database servers.
* **environment** - a complete environment containing a network component and a set of role components.


### Prerequisits
This module is uses the aws command line to probe and change the AWS environment. written and tested using AWS 1.11.45, other versions may work.


### AWS Component Reference

These components are modelled to provide a puppet style representation of the AWS key components.

#### vpc

The vpc component manages the lifecycle of an AWS vpc in a region.  The other networking components associated with the vpc (such as subnets and route tables) are managed seperately.

#### subnet

The subnet component manages the lifecycle of an AWS subnet, within a vpc in an AWS region.  

#### internet_gateway

The internet_gateway component manages the lifecycle of an AWS internet gateway within an AWS region.

#### launch_configuration

The launch_configuration component provides an abstraction of the AWS launch configuration feature, which abstracts away the imutable aspect of AWS launch configurations to present a puppet style resource with modifyable properties.

#### autoscaling_group

The autoscaling_group component manages the lifecycle of an AWS autoscaling group within an AWS region.

#### security_group

The security_group component manages the identity aspect of the AWS security group, enabling association of security groups with AWS networked resources.

#### security\_group\_rules

The security\_group\_rules component manages the ingress and egress rules for a security group. By seperating out the rules from the group enables puppet to create AWS security groups with circular references in the access rules. 

#### load\_balancer

The load\_balancer puppet component manages a subset of the functionality of the AWS elastic load balancer.  It allows basic listener and target setting of the AWS application load balancer.

#### rds

The rds puppet component manages the lifecycle of the AWS RDS component. This component blocks during creation, modifications and deletions until AWS has processed the change.  All changes start immediately and are not delayed to the next maintanence window.

#### rds_subnet

The rds\_subnet component manages the lifecycle of the AWS RDS subnet component. Its principle role is to define which subnets may be used to host the RDS instance(s), taking into account that multi-az RDS instances will have multiple servers running in seperate availability zones to improve resiliance.

#### s3\_bucket

The s3\_bucket component manages the lifecycle and properties of an AWS S3 bucket.

#### s3\_key

The s3\_key component manages the lifecycle and properties of an AWS S3 key.

#### iam\_role

The iam\_role component manages the lifecycle of AWS IAM roles, and which IAM policies are associated with the role.

#### iam\_policy

The iam\_policy component manages the lifecycle of the IAM policy, and the AWS policy permisions granted / denied by the policy.


### Composite Component Reference

These puppet components coordinate multiple AWS components to provide a higher level block of functionality.

#### network

The network component manages a VPC and its subnets with an optional internet gateway.

#### role

The role component creates an scalable application stack that may optionally include database and load balancers.

#### environment

The environment component manages a network containing multiple roles.






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
