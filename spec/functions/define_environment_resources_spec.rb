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
              :dns_resolution=>false
          }
      }
  }

  routetable1 = {
      "resource_type" => "route_table",
      "resources" => {
          "demo"=>{
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
          "demo"=>{
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
          "demo"=>{
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
              :route_table=>"demo",
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
          "demo"=>{
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
          "demo"=>{
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
          "demo"=>{
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

      }
  }

  rds1 = {
      "resource_type" => "rds",
      "resources" => {

      }
  }

  launch_configuration1 = {
      "resource_type" => "launch_configuration",
      "resources" => {

      }
  }

  autoscaling_group1 = {
      "resource_type" => "autoscaling_group",
      "resources" => {

      }
  }

  iam_role1 = {
      "resource_type"=>"iam_role",
      "resources"=>{

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


end

