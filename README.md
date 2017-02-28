# Doatools

#### Table of Contents

1. [A devops AWS / Puppet toolkit](#a-devops-aws-/-puppet-toolkit)
2. [Setup](#setup)
3. [Useage](#usage)
4. [Reference](#reference)

 
## A devops AWS / Puppet toolkit

### Why create yet another puppet AWS component?
This module was created out of a frustration of existing methods for managing AWS infrastructure in a programatic way.  Creating stacks with significant flexibility using Cloud Formation is painful - and easily broken by people making changes using the AWS Console.  The supported puppetlabs AWS components literal implementation around launch configuration / autoscaling groups makes maintaining configurations over time difficult - and cannot manage default routes / security groups on VPC's didnt fit in with my vision on how I would like to use puppet to manage AWS.

### The Vision

Imagine you have to manage a large complex application based around a service orientated architecture within the AWS infrastructure? You need to support multiple server roles - each needing different network access, IAM permisions and software installations. In addition you need to dynamically scale based on the time of day, manage multiple broadly simular deployments for the development processes (each using software at different stages of the development pipeline) and you have the makings of a complex problem.

The long term vision of this module is to incrementally provide the building blocks to solve this challenge. 

### The Current Feature set

This release will enable you to:

1. Declare an AWS VPC with multiple subnets, default routing and an internet gatway to host your application.
2. Declare multiple server roles, with each server role potentially using RDS databases and elastic load balancers as part of its application stack
3. Set the userdata script to configure and install the software onto the servers at first boot.

###  Should I use this module?

If this module's vision is close to the vision you have for your application, that the current feature set meets enough of your immediate needs, and the fact that **this module is still in early development, should be considered beta code and is likely to change significantly as it matures** does not scare you off, then by all means use it.

As a final warning, **at this stage, there is no guarantee of long term resources being applied to this module**


## Setup


This module uses Amazons AWS command line tool to interact with the AWS infrastructure. You will need the following:

* python2 version 2.6.5+, or python3 version 3.3+
* pip
* awscli 1.11.45

```
pip install --upgrade --user awscli==1.11.45
```

The doatools module written and tested using AWS 1.11.45, later versions are highly likely to work, albeit with increasing risk of Amazon introducing a breaking change.


The installation of the module from Puppet Forge is as simple as

```
puppet module install iwifi-doatools
```

This should automatically include the installation of the ruby gems required by this module.

The AWS authentication is handled by the AWS command line application. It assumes that the aws command line can authenticate with AWS without the need for any parameters.  The simplest way to authenticate is to set up your default credentials in the ~/.aws/credentials file.


## Usage

###  Creating AWS resources directly

This module allows you to manage AWS resources directly using the puppet DSL. This example will ensure that a VPC called 'doatools_vpc' exists in the Ohio region.

```
vpc { 'doatools_vpc':
  region => us-east-2
}
```

and by setting ensure to absent, we can make sure it does not exist

```
vpc { 'doatools_vpc':
  ensure => absent,
  region => us-east-2
}  

```

*Notice that we have included the region even in the deletion.  This is important. without specifying the region, puppet will have used the default value for region property (us-east-1), decided that the VPC did not exist and left the vpc in the us-east-2 region still active.*

It is possible to manage all supported AWS components directly at this level.

### Using Higher level resources

This module includes higher level resources that abstract away some of the details (and some control) to make provisioning whole environments quicker and easier to implement.

This example creates a AWS VPC with a functional network and internet connectivity in the ohio region

```
network { 'doatools':
  region => us-east-2
}
```

*This example creates a VPC, 3 subnets and an internet gateway for the same effort.*

This example changes the default security group to only allows HTTP and MySQL traffic between instances

```
network { 'doatools':
  region         => us-east-2,
  default_access => {
    ingress => [ 'tcp|80|sg|doatools', 'tcp|3306|sg|doatools' ],
    egress  => [ 'tcp|80|sg|doatools', 'tcp|3306|sg|doatools' ],
  }
}
```
and to delete the entire network

```
network { 'doatools':
  ensure => absent,
  region => us-east-2
}

```


### Supported AWS Network Components

* vpc
* subnet
* internet\_gateway
* security\_group

### Supported AWS EC2 Components

* elastic load balancer
* launch\_config
* autoscaling\_group

### Supported AWS Storage Components

* rds
* s3_bucket
* s3_key

### Supported AWS IAM Components

* iam_role
* iam_policy


### Application Infrastructure Components

* **network** - a AWS VPC, subnets, route table and internet gateway.
* **role** - An application stack consisting of a launch configuration, autoscaling group and optional load balancers and database servers.
* **environment** - a complete environment containing a network component and a set of role components.




## Reference

These components are modelled to provide a puppet style representation of the key AWS components. To achieve this there are a hand full of abstractions and compromises which are needed to model AWS components as a puppet component

devops engineers will need to bare in mind when implementing systems using these components. They effect the following AWS components:

* launch configuration
* load balancer



#### vpc

The vpc component manages the lifecycle of an AWS vpc in a region.  The other networking components associated with the vpc (such as subnets and route tables) are managed seperately.

* **region** - The AWS region which hosts this component. This property should not be changed after the VPC has been created.
* **cidr** - The CIDR property will be used to set the CIDR in the creation of a new VPC. It is not possible to change the CIDR of an existing VPC. 
* **dns\_hostnames** - The dns_hostnames property controls whether the VPC creates DNS hostname entries for EC2 instances hosted within the VPC.
* **dns\_resolution** - the dns\_resolution property controls whether the VPC contains a DNS resolution service. Disabling dns resolution includes disabling DNS resolution for external systems on the wider internet (*e.g. www.google.com*).

#### subnet

The subnet component manages the lifecycle of an AWS subnet, within a vpc in an AWS region.

* **vpc** - The name of the VPC that hosts this subnet. Changing this property is not supported.
* **region** - The AWS region which hosts this component. This property should not be changed after it has been created.
* **availability\_zone** - The AWS availability zone that hosts this subnet, This property should not be changed after it has been created.
* **cidr** - The CIDR for this subnet.  This property cannot be changed after the subnet has been created.
* **public\_ip** - Do new EC2 instances in this subnet obtain IP addresses by default?
* **routetable** - The name of the AWS route table associated with this subnet.


#### internet_gateway

The internet_gateway component manages the lifecycle of an AWS internet gateway within an AWS region.

* **environment** - The name of the environment that this internet gateway is logically contained.
* **vpc** - The name of the VPC that is attached to this internet gateway.
* **region** - The name of the AWS region which hosts this AWS internet gateway component.



#### launch_configuration

The launch_configuration component provides an abstraction of the AWS launch configuration feature, which abstracts away the imutable aspect of AWS launch configurations to present a puppet style resource with modifyable properties.

* **region** - The name of the AWS region which hosts this AWS launch configuration.
* **image** - The ami id of the AWS image used as the base image when starting new EC2 instances.
* **instance\_type** - The AWS instance type that will be created using this launch configuration
* **security\_groups** - An array of security group names from the same AWS region that should be attached to new instances.
* **user\_data** - The userdata script that is used to configure and install the software onto the EC2 instance at start up.
* **ssh\_key\_name** - The name of the AWS SSH registered key that should be used to obtain access to the new instance.

*The puppet model for launch configurations is updateable despite the AWS implementation following a copy on write model. When looking at the AWS console, launch configuration names will be appended with versioning data in the form \_=[0-9a-zA-Z]{3..3}=. When a change happens in the puppet configuration, a new AWS configuration is created, and any puppet AutoScaling configurations referencing the modified launch configuration are updated to use the new launch configuration.  The launch configuration history older than the previous 4 revisions is also deleted. This should be largely transparent.*

*There is currently no implementation to rotate existing instances into new instances using the new launch configuration settings.* 

#### autoscaling_group

The autoscaling_group component manages the lifecycle of an AWS autoscaling group within an AWS region.

* **region** - The name of the AWS region which hos ts this AWS launch configuration.
* **desired\-instances** - The number of EC2 instances that it is desirable to maintain within this autoscaling group.
* **minimum\_instances** - The minimum number of EC2 instances that is acceptable to form part of this autoscaling group.
* **maximum\_instances** - The maximum number of EC2 instances that is acceptable to form part of this autoscaling group.
* **launch\_configuration** - The name of the puppet launch configuration to use in the creation of new EC2 instances. This property is always updated on the AWS component to use the latest AWS version of the named launch configuration.
* **subnets** - The array of subnet names that may be used to launch new EC2 instances within this autoscaling group.
* **healthcheck_grace** - The time in seconds after a new EC2 instance has been created, before it becomes subject to termination on failing a health check
* **healthcheck_type** - Determines if the health check is performed by using load balancer health checks, or by the EC2 status checks.


#### security_group

The security_group component manages the identity aspect of the AWS security group, enabling association of security groups with AWS networked resources.

* **vpc** - The name of the puppet VPC that is associated with this security group.  This cannot be changed after creation.
* **region** - The name of the AWS region that hosts this security group.
* **environment** - The name of the logical puppet environment that is associated with this security group.
* **description** - The description of the purpose of this security group. This cannot be changed after creation.


#### security\_group\_rules

The security\_group\_rules component manages the ingress and egress rules for a security group. By seperating out the rules from the group enables puppet to create AWS security groups with circular references in the access rules.

* **region** - The name of the AWS region that hosts this security group.
* **security\_group** - The name of the security group that implements these rules.
* **in** - The rules to apply to inbound network traffic.
* **out** - The rules to apply to outbound network traffic.

#### load\_balancer

The load\_balancer puppet component manages a subset of the functionality of the AWS elastic load balancer.  It allows basic listener and target setting of the AWS application load balancer.

* **region** - The name of the AWS region that hosts this load balancer.
* **subnets** - The list of subnets that the load balancer will use to host the load balancer.
* **listeners** - The list of ports, protocols (and with HTTPS, certificates) that the load balancer accepts incomming connections.
* **targets** - The set of properties that the load balancer uses to connect and health check the upstream web servers.

listeners is an array of strings following these formats:

```
http://[target-name]:[port]
https://[target-name]:[port]?certificate=[certificate-arn]
```

targets is a single entry in an array defining the target port, vpc and health check parameters

e.g.

```
[{
  name => 'mytarget',
  port => 80,
  check_interval => 30,
  timeout => 10,
  healthy => 3,
  failed => 2,
  vpc => 'example',
}]
```

#### rds

The rds puppet component manages the lifecycle of the AWS RDS component. This component blocks during creation, modifications and deletions until AWS has processed the change.  All changes start immediately and are not delayed to the next maintanence window.

* **region** - The AWS region that hosts this RDS instance.
* **engine** - the RDS engine to use on the RDS instance.
* **engine\_version** - The software version of the database engine.
* **master\_username** - The AWS admin username for the RDS instance.
* **master\_password** - The AWS admin users password for the RDS instance.
* **database** - The default database to create in the RDS instance at creation.
* **db\_subnet\_group** - The RDS Subnet group name used to define possible subnets for the RDS instance.
* **maintenance\_window** - The time range that AWS can use for automated actions on the RDS instance. This may involve the RDS instance being unavailable during this time frame.
* **backup\_window** - The time range that AWS uses to run the backup of the RDS instance.
* **backup\_retention\_count** - The numnber of historic backups for AWS to store.
* **instance\_type** - The RDS instance type to use.
* **security\_groups** - This list of security groups that manage network traffic to this instance
* **multi_az** - a boolean flag controlling whether this RDS instance is multi-az or single az.
* **storage\_type** - The type of disk storage media to use on this RDS instance.
* **storage\_size** - The size of disk space available on the RDS instance.
* **license\_model** - The licensing model to use. The default model varies by engine type.
* **public\_access** - Does the RDS instance need a public IP address?
* **iops** - With the SSD storage type, you can request higher IO bandwidth for the RDS instance.

Valid engine settings are:

* mysql
* mariadb
* oracle-se1
* oracle-se2
* oracle-se
* oracle-ee
* sqlserver-ee
* sqlserver-se
* sqlserver-ex
* sqlserver-web
* postgres
* aurora

Valid license models are:

* license-included
* bring-your-own-license
* general-public-license



#### rds_subnet_group

The rds\_subnet component manages the lifecycle of the AWS RDS subnet component. Its principle role is to define which subnets may be used to host the RDS instance(s), taking into account that multi-az RDS instances will have multiple servers running in seperate availability zones to improve resiliance.

* **region** - The AWS region that hosts the RDS subnet group.
* **subnets** - The array of subnet names that are part of this subnet group.
* **description** - The description of the RDS subnet group.


#### s3\_bucket

The s3\_bucket component manages the lifecycle and properties of an AWS S3 bucket.

* **region** - The AWS region that hosts the S3 bucket.
* **policy** - The array of S3 bucket access policy statements.
* **grants** - The array of S3 bucket access grants.
* **cors** - The permisions for web browser scripted access to public S3 components within this bucket.

#### s3\_key

The s3\_key component manages the lifecycle and properties of an AWS S3 key.

* **name** - An S3 path specifying the bucket and full path for this S3 key.
* **content** - The content of the S3 key.
* **grants** - Grant AWS account / public permisions for a specific key.
* **owner** - a string of the format acc|[name]|[aws id] to create the key as owned by a different AWS account.
* **metadata** - A JSON hash containing key/value pairs for the metadata associated with this s3 key.


#### iam\_role

The iam\_role component manages the lifecycle of AWS IAM roles, and which IAM policies are associated with the role.

* **policies** - The list of AWS IAM policies that are granted by this IAM role.
* **tust** - The list of AWS services that can assume this role.


#### iam\_policy

The iam\_policy component manages the lifecycle of the IAM policy, and the AWS policy permisions granted / denied by the policy.

* **policy** - A list of policy statements that form the set of permisions associated with this IAM policy.


### Composite Component Reference

These puppet components coordinate multiple AWS components to provide a higher level block of functionality.

#### network

The network component manages a VPC and its subnets with an optional internet gateway.

* **region** - The AWS region that hosts this VPC.
* **vpc_cidr** - The CIDR for the entire VPC
* **environment** - The name of the environment that is hosted within this VPC.
* **availability** - The list of the availability zone letters that are to be used by this VPC.
* **zones** - The list of zones to create within this VPC.
* **internet\_access** - Does this VPC have an internet access gateway?
* **default\_access** - The access rules for the default security group.

zones are an abstraction of subnets within the AWS environment. Rather than requiring the configuration to define each subnet in detail, the configuration defines one or more zones, and each zone has a subnet created in each availability zone automatically.  The internal CIDR space for each zone is shared equally across each subnet.

Each zone entry is a hash of the following keys:

* label - The name of the zone, used as part of the name of the underlying subnets.
* cidr - The cidr for the whole zone.
* public_ip - Sets whether the subnets grant public IP addresses by default.


#### role

The role component creates an scalable application stack that may optionally include database and load balancers.

* **region** - The AWS region that hosts this role.
* **vpc** - The name of the VPC to use to host this role.
* **instance\_type** - The EC2 instance type to use as compute resources for this role.
* **image** - The AMI image id to use as the base image for this role.
* **min** - The minimum number of EC2 instances for this role.
* **max** - The maximum number of EC2 instances for this role.
* **desired** - The desired number of EC2 instances for this role.
* **availability** - The list of availability zone letters to use for this role.
* **zone_label** - The name of the network zone to use for hosting this roles EC2 instances.
* **listeners** - The list of listeners for the elastic load balancer. Set to undef to not have a load balancer.
* **target** - The Load balancer target properties that can contain [port|check_interval|timeout|healthy|failed]
* **database** - A hash of properties to define the RDS instance (or undef for no RDS instance).


#### environment

The environment component manages a network containing multiple roles.

* **region** - The AWS region that hosts this role
* **network** - A hash map of properties for the network component. The environment region property is used as the network region value.
* **roles** - A hash map of role properties, containing the non default properties for each role that is formed as part of this environment. 

A simple example of the roles property declaring two seperate roles:

```
roles => {
      test1 => {
        image => 'ami-6d1c2007',
        desired => 3
      },
      test2 => {
        image => 'ami-6d1c2007',
        desired => 5
      }

```



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
