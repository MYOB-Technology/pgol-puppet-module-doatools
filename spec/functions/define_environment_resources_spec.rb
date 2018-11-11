require 'spec_helper'

describe 'define_environment_resources' do
  vpc1 = {
      "resource_type"=>"vpc",
      "resources"=>{
          "demo"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :cidr=>"192.168.0.0/24",
              :tags=>{"Environment"=>"demo"},
              :dns_hostnames=>false,
              :dns_resolution=>true
          }
      }
  }

  routetable1 = {
      "resource_type" => "route_table",
      "resources" => {
          "demopublicall"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          }

      }
  }

  routetable2 = {
      "resource_type" => "route_table",
      "resources" => {
          "demopublicall"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },
          "demonata"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },

      }
  }

  routetable3 = {
      "resource_type" => "route_table",
      "resources" => {
          "demopublicall"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },
          "demonata"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },
          "demonatb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },
          "demonatc"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :tags=>{
                  "Environment"=>"demo"
              }
          },
      }
  }


  subnets1 = {
      "resource_type"=>"subnet",
      "resources"=>{
          "demopublica"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"a",
              :cidr=>"192.168.0.0/26",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          },
          "demopublicb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"b",
              :cidr=>"192.168.0.64/26",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          }, "demopublicc" => {
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"c",
              :cidr=>"192.168.0.128/26",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          }
      }
  }

  subnets2 = {
      "resource_type"=>"subnet",
      "resources"=>{
          "demopublica"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"a",
              :cidr=>"192.168.0.0/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          },
          "demopublicb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"b",
              :cidr=>"192.168.0.32/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          }, "demopublicc" => {
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"c",
              :cidr=>"192.168.0.64/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          },
          "demonata"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"a",
              :cidr=>"192.168.0.96/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonata",
              :public_ip=>false
          },
          "demonatb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"b",
              :cidr=>"192.168.0.128/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonata",
              :public_ip=>false
          }, "demonatc" => {
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"c",
              :cidr=>"192.168.0.160/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonata",
              :public_ip=>false
          }
      }
  }

  subnets3 = {
      "resource_type"=>"subnet",
      "resources"=>{
          "demopublica"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"a",
              :cidr=>"192.168.0.0/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          },
          "demopublicb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"b",
              :cidr=>"192.168.0.32/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          }, "demopublicc" => {
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"c",
              :cidr=>"192.168.0.64/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demopublicall",
              :public_ip=>true
          },
          "demonata"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"a",
              :cidr=>"192.168.0.96/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonata",
              :public_ip=>false
          },
          "demonatb"=>{
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"b",
              :cidr=>"192.168.0.128/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonatb",
              :public_ip=>false
          }, "demonatc" => {
              :ensure=>"present",
              :region=>"us-east-1",
              :vpc=>"demo",
              :availability_zone=>"c",
              :cidr=>"192.168.0.160/27",
              :tags=>{
                  "Environment"=>"demo"
              },
              :route_table=>"demonatc",
              :public_ip=>false
          }
      }
  }


  security_group1 = {
      "resource_type" => "security_group",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              }
          }
      }
  }
  security_group1a = {
      "resource_type" => "security_group",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              }
          },
          "demo_testdb" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              },
              :description => "database security group"
          }
      }
  }



  security_group2 = {
      "resource_type" => "security_group",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              }
          },
          "demo_my_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              },
              :description => "Service security group"
          }
      }
  }

  security_group3 = {
      "resource_type" => "security_group",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              }
          },
          "demo_my_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              },
              :description => "Service security group"
          },
          "demo_my_other_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              },
              :description => "Service security group"
          },
          "demo_testdb" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :tags => {
                  "Environment" => "demo"
              },
              :description => "database security group"
          }
      }
  }



  security_group_rules1 = {
      "resource_type" => "security_group_rules",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [],
              :out => [],
          }
      }
  }

  security_group_rules1a = {
      "resource_type" => "security_group_rules",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [],
              :out => [],
          },
          "demo_testdb" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [],
              :out => [],
          }
      }
  }

  security_group_rules2 = {
      "resource_type" => "security_group_rules",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [],
              :out => [],
          },
          "demo_my_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [
                  "tcp|22|cidr|0.0.0.0/0"
              ],
              :out => [
                  "tcp|80|cidr|0.0.0.0/0",
                  "tcp|443|cidr|0.0.0.0/0"
              ],
          }
      }
  }

  security_group_rules3 = {
      "resource_type" => "security_group_rules",
      "resources" => {
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [],
              :out => [],
          },
          "demo_my_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [
                  "tcp|22|cidr|0.0.0.0/0",
                  "tcp|80|sg|demo_testrole_elb",
              ],
              :out => [
                  "tcp|80|cidr|0.0.0.0/0",
                  "tcp|443|cidr|0.0.0.0/0",
                  "tcp|3306|sg|demo_testdb"
              ],
          },
          "demo_my_other_srv" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [
                  "tcp|22|cidr|0.0.0.0/0",
                  "tcp|8000|sg|demo_my_other_srv"
              ],
              :out => [
                  "tcp|80|cidr|0.0.0.0/0",
                  "tcp|443|cidr|0.0.0.0/0",
                  "tcp|8000|sg|demo_my_other_srv"
              ],
          },
          "demo_testdb" => {
              :ensure => "present",
              :region => "us-east-1",
              :in => [
                  "tcp|3306|sg|demo_my_srv"
              ],
              :out => [ ],
          }

      }
  }



  internet_gateway1 = {
      "resource_type"=>"internet_gateway",
      "resources"=>{
        "demo" => {
            :ensure => "present",
            :region => "us-east-1",
            :vpc => "demo",
            :nat_gateways => [],
        }
      }
  }

  internet_gateway2 = {
      "resource_type"=>"internet_gateway",
      "resources"=>{
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :nat_gateways => [ "demonata" ],
          }
      }
  }

  internet_gateway3 = {
      "resource_type"=>"internet_gateway",
      "resources"=>{
          "demo" => {
              :ensure => "present",
              :region => "us-east-1",
              :vpc => "demo",
              :nat_gateways => [ "demonata", "demonatb", "demonatc" ],
          }
      }
  }

  nat_gateway1 = {
      "resource_type" => "nat_gateway",
      "resources" => {

      }
  }

  nat_gateway2 = {
      "resource_type" => "nat_gateway",
      "resources" => {
          "demonata" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.1",
              :internet_gateway => 'demo'
          }
      }
  }

  nat_gateway3 = {
      "resource_type" => "nat_gateway",
      "resources" => {
          "demonata" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.1",
              :internet_gateway => 'demo'
          },
          "demonatb" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.2",
              :internet_gateway => 'demo'
          },
          "demonatc" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.3",
              :internet_gateway => 'demo'
          }
      }
  }

  route_table_routes1 = {
      "resource_type" => "route_table_routes",
      "resources" => {
          "demopublicall"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|igw|demo'
              ]
          }
      }
  }

  route_table_routes2 = {
      "resource_type" => "route_table_routes",
      "resources" => {
          "demopublicall"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|igw|demo'
              ]
          },
          "demonata"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|nat|demonata'
              ]
          }
      }
  }

  route_table_routes3 = {
      "resource_type" => "route_table_routes",
      "resources" => {
          "demopublicall"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|igw|demo'
              ]
          },
          "demonata"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|nat|demonata'
              ]
          },
          "demonatb"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|nat|demonatb'
              ]
          },
          "demonatc"=>{
              :ensure => "present",
              :region => "us-east-1",
              :routes => [
                  '0.0.0.0/0|nat|demonatc'
              ]
          },
      }
  }


  load_balancers1 = {
      "resource_type" => "load_balancer",
      "resources" => {

      }
  }

  rds_subnet_group1 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
          "demo-public" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
      }
  }

  rds_subnet_group2 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
          "demo-public" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
          "demo-nat" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
      }
  }

  rds_subnet_group3 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
          "demo-public" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
          "demo-nat" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
          "demo-private" => {
              :ensure => "absent",
              :region => "us-east-1",
          }
      }
  }

  rds_subnet_group4 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
        "demo-nat" => {
            :ensure => "present",
            :region => "us-east-1",
            :subnets => [
                'demonata',
                'demonatb',
                'demonatc',
            ]
        },
        "demo-public" => {
            :ensure => "absent",
            :region => "us-east-1",
        },
      }
  }

  rds_subnet_group5 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
          "demo-public" => {
              :ensure => "present",
              :region => "us-east-1",
              :subnets => [
                  'demopublica',
                  'demopublicb',
                  'demopublicc',
              ]
          },
          "demo-nat" => {
              :ensure => "absent",
              :region => "us-east-1",
          },
      }
  }

  rds_subnet_group6 = {
      "resource_type" => "rds_subnet_group",
      "resources" => {
          "demo-public" => {
              :ensure => "present",
              :region => "us-east-1",
              :subnets => [
                  'demopublica',
                  'demopublicb',
                  'demopublicc',
              ]
          },
      }
  }

  rds1 = {
      "resource_type" => "rds",
      "resources" => {

      }
  }


  rds2 = {
      "resource_type" => "rds",
      "resources" => {
          "demo-testdb" => {
              "master_username"=>"admin",
              "master_password"=>"password!",
              "database"=>"testdb",
              "multi_az"=>"false",
              "public_access"=>"false",
              "instance_type"=>"db.t2.micro",
              "storage_size"=>"50",
              "rds_subnet_group"=>"demo-nat",
              "ensure"=>"present",
              "region"=>"us-east-1",
              "security_groups"=>[
                "demo_testdb"
              ]
          }
      }
  }

  rds3 = {
      "resource_type" => "rds",
      "resources" => {
          "demo-testdb" => {
              "master_username"=>"admin",
              "master_password"=>"fred",
              "database"=>"testdb",
              "multi_az"=>"false",
              "public_access"=>"false",
              "instance_type"=>"db.t2.micro",
              "storage_size"=>"50",
              "ensure"=>"present",
              "region"=>"us-east-1",
              "security_groups"=>[
                  "demo_testdb"
              ],
              "rds_subnet_group"=>"demo-public"
          }
      }
  }


  launch_configuration1 = {
      "resource_type" => "launch_configuration",
      "resources" => {

      }
  }

  launch_configuration2 = {
      "resource_type" => "launch_configuration",
      "resources" => {
          "demotestrole" => {
              "instance_type"=>"t2.micro",
              "image"=>"ami-6d1c2007",
              "ensure"=>"present",
              "region"=>"us-east-1",
              "security_groups"=>[
                  "demo_my_srv"
              ],
              "iam_instance_profile"=>[
                  "demo_testrole"
              ],
              "public_ip"=> :enabled
          }
      }
  }

  launch_configuration3 = {
      "resource_type" => "launch_configuration",
      "resources" => {
          "demotestrole" => {
              "instance_type"=>"t2.micro",
              "image"=>"ami-6d1c2007",
              "ensure"=>"present",
              "region"=>"us-east-1",
              "security_groups"=>[
                  "demo_my_srv",
                  "demo_my_other_srv"
              ],
              "iam_instance_profile"=>[
                  "demo_testrole"
              ],
              "public_ip"=> :enabled
          }
      }
  }



  autoscaling_group1 = {
      "resource_type" => "autoscaling_group",
      "resources" => {

      }
  }

  autoscaling_group2 = {
      "resource_type" => "autoscaling_group",
      "resources" => {
          "demotestrole" => {
              "ensure"=>"present",
              "region"=>"us-east-1",
              "launch_configuration"=>"demo_testrole",
              "subnets"=>[
                  "demopublica",
                  "demopublicb",
                  "demopublicc",
              ],
              "minimum_instances"=>0,
              "maximum_instances"=>2,
              "desired_instances"=>2,
          }
      }
  }



  iam_role1 = {
      "resource_type"=>"iam_role",
      "resources"=>{

      }
  }

  iam_role2 = {
      "resource_type"=>"iam_role",
      "resources"=>{
          "demo_testrole" => {
              :ensure=>"present",
              :policies=>[]
          }
      }
  }




  iam_policies_1 = {
      "resource_type" => "iam_policy",
      "resources" => {

      }
  }
  iam_instance_profile1 = {
      "resource_type" => "iam_instance_profile",
      "resources" => {

      }
  }

  iam_instance_profile2 = {
      "resource_type" => "iam_instance_profile",
      "resources" => {
          "demo_testrole"=>{
              :ensure=>"present",
              :iam_role=>"demo_testrole"
          }
      }
  }


  s3_bucket1 = {
      "resource_type" => "s3_bucket",
      "resources" => {

      }
  }

  s3_key1 = {
      "resource_type" => "s3_key",
      "resources" => {

      }
  }


  context 'creating an environment with a public zone' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { }
        },
        {},
        {},
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {
        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group1,
            security_group_rules1,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers1,
            rds_subnet_group1,
            rds1,
            launch_configuration1,
            autoscaling_group1,
            iam_role1,
            iam_policies_1,
            iam_instance_profile1,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public and nat zone' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { },
            'nat' => {
                'nat_ipaddr' => '148.88.8.1'
            }
        },
        {},
        {},
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {
        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable2,
            subnets2,
            security_group1,
            security_group_rules1,
            internet_gateway2,
            nat_gateway2,
            route_table_routes2,
            load_balancers1,
            rds_subnet_group2,
            rds1,
            launch_configuration1,
            autoscaling_group1,
            iam_role1,
            iam_policies_1,
            iam_instance_profile1,
            s3_bucket1,
            s3_key1
        ])
    }
  end


  context 'creating an environment with a public and nat zone with multiple nat gateways' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { },
            'nat' => {
                'nat_ipaddr' => [
                    '148.88.8.1',
                    '148.88.8.2',
                    '148.88.8.3',
                ]
            }
        },
        {},
        {},
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {
        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable3,
            subnets3,
            security_group1,
            security_group_rules1,
            internet_gateway3,
            nat_gateway3,
            route_table_routes3,
            load_balancers1,
            rds_subnet_group2,
            rds1,
            launch_configuration1,
            autoscaling_group1,
            iam_role1,
            iam_policies_1,
            iam_instance_profile1,
            s3_bucket1,
            s3_key1
        ])
    }
  end


  context 'creating an environment with a public and nat zone with a database' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { },
            'nat' => {
                'nat_ipaddr' => [
                    '148.88.8.1',
                    '148.88.8.2',
                    '148.88.8.3',
                ]
            }
        },
        {},
        {},
        {
            'testdb' => { },
        },
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {
        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable3,
            subnets3,
            security_group1a,
            security_group_rules1a,
            internet_gateway3,
            nat_gateway3,
            route_table_routes3,
            load_balancers1,
            rds_subnet_group4,
            rds2,
            launch_configuration1,
            autoscaling_group1,
            iam_role1,
            iam_policies_1,
            iam_instance_profile1,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public and nat zone with a database in the public zone' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { },
            'nat' => {
                'nat_ipaddr' => [
                    '148.88.8.1',
                    '148.88.8.2',
                    '148.88.8.3',
                ]
            }
        },
        {},
        {},
        {
            'testdb' => {
                'zone' => 'public',
                'master_password' => 'fred'
            },
        },
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {
        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable3,
            subnets3,
            security_group1a,
            security_group_rules1a,
            internet_gateway3,
            nat_gateway3,
            route_table_routes3,
            load_balancers1,
            rds_subnet_group5,
            rds3,
            launch_configuration1,
            autoscaling_group1,
            iam_role1,
            iam_policies_1,
            iam_instance_profile1,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone and a role' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { }
        },
        {
            "testrole" => {
                "ec2" => {
                    "instance_type" => 't2.micro',
                    "image" => 'ami-6d1c2007',
                },
                "zone" => 'public',
                "services" => [
                    "my_srv"
                ],
            }
        },
        {
            "my_srv" => {
                "network" => {
                    "in" => [
                        "tcp|22|cidr|0.0.0.0/0",
                    ],
                    "out" => [
                        "tcp|80|cidr|0.0.0.0/0",
                        "tcp|443|cidr|0.0.0.0/0",
                    ]
                }
            }
        },
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {

        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group2,
            security_group_rules2,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers1,
            rds_subnet_group1,
            rds1,
            launch_configuration2,
            autoscaling_group2,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end


  context 'creating an environment with a public zone, a role and some more complex networking rules' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { }
        },
        {
            "testrole" => {
                "ec2" => {
                    "instance_type" => 't2.micro',
                    "image" => 'ami-6d1c2007',
                },
                "zone" => 'public',
                "services" => [
                    "my_srv"
                ],
            }
        },
        {
            "my_srv" => {
                "network" => {
                    "in" => [
                        "tcp|22|cidr|0.0.0.0/0",
                        "tcp|80|rss|elb"
                    ],
                    "out" => [
                        "tcp|80|cidr|0.0.0.0/0",
                        "tcp|443|cidr|0.0.0.0/0",
                        "tcp|3306|rds|testdb"
                    ]
                }
            },
            "my_other_srv" => {
                "network" => {
                    "in" => [
                        "tcp|22|cidr|0.0.0.0/0",
                        "tcp|80|rss|elb",
                        "tcp|8000|service|my_other_srv"
                    ],
                    "out" => [
                        "tcp|80|cidr|0.0.0.0/0",
                        "tcp|443|cidr|0.0.0.0/0",
                        "tcp|8000|service|my_other_srv"
                    ]
                }
            }
        },
        {
            'testdb' => {
                'zone' => 'public',
                'master_password' => 'fred'
            },
        },
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {

        },
        {
        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group3,
            security_group_rules3,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers1,
            rds_subnet_group6,
            rds3,
            launch_configuration2,
            autoscaling_group2,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone, a role and some more complex networking rules' do
    it { is_expected.to run.with_params(
        'demo', 'present', 'us-east-1',
        {
            'cidr' => "192.168.0.0/24",
            'availability' => [ "a", "b", "c"]
        },
        {
            'public' => { }
        },
        {
            "testrole" => {
                "ec2" => {
                    "instance_type" => 't2.micro',
                    "image" => 'ami-6d1c2007',
                },
                "zone" => 'public',
                "services" => [
                    "my_srv",
                    "my_other_srv"
                ],
            }
        },
        {
            "my_srv" => {
                "network" => {
                    "in" => [
                        "tcp|22|cidr|0.0.0.0/0",
                        "tcp|80|rss|elb"
                    ],
                    "out" => [
                        "tcp|80|cidr|0.0.0.0/0",
                        "tcp|443|cidr|0.0.0.0/0",
                        "tcp|3306|rds|testdb"
                    ]
                }
            },
            "my_other_srv" => {
                "network" => {
                    "in" => [
                        "tcp|22|cidr|0.0.0.0/0",
                        "tcp|8000|service|my_other_srv"
                    ],
                    "out" => [
                        "tcp|80|cidr|0.0.0.0/0",
                        "tcp|443|cidr|0.0.0.0/0",
                        "tcp|8000|service|my_other_srv"
                    ]
                }
            }
        },
        {
            'testdb' => {
                'zone' => 'public',
                'master_password' => 'fred'
            },
        },
        {},
        {
            'Environment' => 'demo'
        },
        {

        },
        {

        },
        {

        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group3,
            security_group_rules3,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers1,
            rds_subnet_group6,
            rds3,
            launch_configuration3,
            autoscaling_group2,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end



end



