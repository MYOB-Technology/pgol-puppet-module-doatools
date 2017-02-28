# Examples

## Running the examples

When you run the examples, puppet will instruct AWS to create and delete resources in your AWS account. The implications of this include AWS charges added to your bill and there is always the potential for deletion of your critical infrastructure within AWS.

We recomend that you:

 * Use a seperate AWS account.
 * Use the --noop and --debug parameters to verify which AWS commands will be executed.
 * Verify the current running costs with AWS
 * Use the AWS console to verify that all AWS components are properly terminated.


## VPC

* [Create a simple VPC with subnets](vpc with subnets/create.pp)
* [Create a vpc, subnets, internet gateway and security groups](vpc with security groups and internet gateway/create.pp)
* [Creating a simple network resource](network resource/create.pp)

## Application Stacks

* [Create an autoscaling group and launch configuration](autoscaling group and launch configuration/create.pp)
* [Create a MySQL RDS Instance](rds with mysql/create.pp)
* [Create a Load Balancer](elastic load balancer/create.pp)
* [Create a complete application stack as a Role](application stack/create.pp)

## IAM permisions

* Create an IAM role granting permision to access S3

## Environment

* [Create an environment with a single role](environment with a single role/create.pp)
* [Create an environment with multiple roles, one using a load balancer and a database](environment with mulltiple roles load balancer and a database/create.pp)

