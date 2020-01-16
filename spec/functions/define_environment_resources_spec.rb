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

  security_group4 = {
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
        "demo_testrole" => {
            :ensure => "present",
            :region => "us-east-1",
            :vpc => "demo",
            :tags => {
                "Environment" => "demo"
            },
            :description => "Role security group"
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

  security_group5 = {
    "resource_type" => "security_group", 
    "resources" => {
      "demo_my_srv"=>{:ensure=>"present", :region=>"us-east-1", :vpc=>"demo", :tags=>{"Environment"=>"demo"}, :description=>"Service security group"}, 
      "demo_testrole_elb"=>{:ensure=>"present", :region=>"us-east-1", :vpc=>"demo", :tags=>{"Environment"=>"demo"}, :description=>"load balancer security group"}, 
      "demo"=>{:ensure=>"present", :region=>"us-east-1", :vpc=>"demo", :tags=>{"Environment"=>"demo"}}
    }
  }

  security_group_rules5 = {
    "resource_type" => "security_group_rules", 
    "resources" => {
      "demo" => {:ensure=>"present", :region=>"us-east-1", :in=>[], :out=>[]}, 
      "demo_my_srv"=>{:ensure=>"present", :region=>"us-east-1", :in=>["tcp|22|cidr|0.0.0.0/0"], :out=>["tcp|80|cidr|0.0.0.0/0", "tcp|443|cidr|0.0.0.0/0"]}, 
      "demo_testrole_elb"=>{:ensure=>"present", :region=>"us-east-1", :in=>["tcp|443|cidr|0.0.0.0/0"], :out=>["tcp|443|sg|demo_my_srv"]}} 
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

  security_group_rules4= {
    "resource_type" => "security_group_rules",
    "resources" => {
        "demo" => {
            :ensure => "present",
            :region => "us-east-1",
            :in => [],
            :out => [],
        },
        "demo_testrole" => {
          :ensure => 'present',
          :region => 'us-east-1',
          :in => [
            "tcp|22|cidr|0.0.0.0/0",
            "tcp|80|sg|demo_testrole_elb",
            "tcp|8000|sg|demo_testrole"
          ],
          :out => [
            "tcp|80|cidr|0.0.0.0/0",
            "tcp|443|cidr|0.0.0.0/0",
            "tcp|3306|sg|demo_testdb",
            "tcp|8000|sg|demo_testrole"
          ]
        },
        "demo_testdb" => {
            :ensure => "present",
            :region => "us-east-1",
            :in => [
                "tcp|3306|sg|demo_testrole"
            ],
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
              :internet_gateway => 'demo',
              :subnet => "demopublica"
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
              :internet_gateway => 'demo',
              :subnet => "demopublica",
          },
          "demonatb" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.2",
              :internet_gateway => 'demo',
              :subnet => "demopublicb",
          },
          "demonatc" => {
              :ensure => "present",
              :region => "us-east-1",
              :elastic_ip => "148.88.8.3",
              :internet_gateway => 'demo',
              :subnet => "demopublicc",
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

  load_balancers2 = {
    "resource_type"=>"load_balancer", 
    "resources"=> {
      "demo-testrole" => {
        :ensure=>"present", 
        :region=>"us-east-1", 
        :subnets=>["demopublica", "demopublicb", "demopublicc"], 
        :listeners=>["https://testrole-https-443-to-443:443"], 
        :targets=>[{"name"=>"testrole-https-443-to-443", "protocol" => 'https', "port"=>'443', "check_interval"=>30, "timeout"=>5, "healthy"=>5, "failed"=>2, "vpc"=>"demo"}], 
        :security_groups=>["demo_testrole_elb"]
      }
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
              "iam_instance_profile"=> "demotestrole",
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
              "iam_instance_profile"=> "demotestrole",
              "public_ip"=> :enabled
          }
      }
  }

  launch_configuration4 = {
    "resource_type" => "launch_configuration",
    "resources" => {
        "demotestrole" => {
            "instance_type"=>"t2.micro",
            "image"=>"ami-6d1c2007",
            "ensure"=>"present",
            "region"=>"us-east-1",
            "security_groups"=> "demo_testrole",
            "iam_instance_profile"=> "demotestrole",
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
    'resource_type' => 'autoscaling_group',
    'resources' => {
      'demotestrole' => {
        :ensure=>'present',
        :region=>'us-east-1',
        :launch_configuration=>'demotestrole',
        :subnets=>[
          'demopublica',
          'demopublicb',
          'demopublicc',
        ],
        :tags => { 'Role' => 'testrole', 'Name' => 'testrole_demo' },
        :minimum_instances=>0,
        :maximum_instances=>2,
        :desired_instances=>2,
        :load_balancer => []
      }
    }
  }

  autoscaling_group3 = { 
    'resource_type'=>'autoscaling_group', 
    'resources'=>{
      'demotestrole'=>{
        :ensure=>'present', 
        :region=>'us-east-1', 
        :launch_configuration=>'demotestrole', 
        :subnets=>['demopublica', 'demopublicb', 'demopublicc'], 
        :tags=>{'Role'=>'testrole', 'Name'=>'testrole_demo'}, 
        :minimum_instances=>0, 
        :desired_instances=>2, 
        :maximum_instances=>2, 
        :load_balancer=>['testrole-https-443-to-443'] 
      }
    }
  }

  deployment_group1 = {
      "resource_type" => "deployment_group",
      "resources" => {}
  }

  deployment_group2 = {
      "resource_type" => "deployment_group",
      "resources" => {
        "demodeploy" => {
            "ensure"=>"present",
            "region"=>"us-east-1",
            "application_name"=>"appname",
            "service_role"=>"democodedeploy",
            "autoscaling_groups"=>[
              "demotestrole"
            ],
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
          "demotestrole" => {
              :ensure=>"present",
              :policies=>[]
          }
      }
  }

  iam_role3 = {
      "resource_type"=>"iam_role",
      "resources"=>{
          "demotestrole" => {
              :ensure=>"present",
              :policies=>[]
          },
          "democodedeploy" => {
              :ensure=>"present",
              :policies=>[ "AWSCodeDeployRole"],
              :trust=>["codedeploy"],
          }
      }
  }

  iam_role4 = {
    "resource_type"=>"iam_role",
    "resources"=>{
      "demotestrole" => {
        :ensure=>"present",
        :policies=>['demoadmin_policy']
      }
    }
  }

  iam_policies_1 = {
      "resource_type" => "iam_policy",
      "resources" => {

      }
  }

  iam_policies_2 = {
    "resource_type" => "iam_policy",
    "resources" => {
      "demoadmin_policy" => {
        :ensure => "present",
        :policy => [{
          "Effect" => "Allow",
          "Action" => "*",
          "Resource" => "*"
        }]
      }
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
          "demotestrole"=>{
              :ensure=>"present",
              :iam_role=>"demotestrole"
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

  route53_record_set1 = {
    "resource_type" => "route53_record_set",
    "resources" => {}
  }

  route53_record_set2 = {
    "resource_type" => "route53_record_set",
    "resources" => {
      'demo-fs.pgol-record-set' => {
        :ensure       => 'present',
        :region       => 'us-east-1',
        :hosted_zone  => 'fs.pgol.',
        :record_set   => [
          {
            :Name =>  'pg1000nz.fs.pgol.',
            :Type => 'CNAME',
            :Ttl => 60,
            :Values => ['sy1-db1.internal.myobpayglobal.com']
          },
          {
            :Name =>  'pg1001nz.fs.pgol.',
            :Type => 'CNAME',
            :Ttl => 60,
            :Values => ['sy1-db1.internal.myobpayglobal.com']
          }
        ]
      },
      'demo-db.pgol-record-set' => {
        :ensure       => 'present',
        :region       => 'us-east-1',
        :hosted_zone  => 'db.pgol.',
        :record_set   => [
          {
            :Name =>  'pg1000nz.db.pgol.',
            :Type => 'CNAME',
            :Ttl => 60,
            :Values => ['sy1-db1.internal.myobpayglobal.com']
          },
          {
            :Name =>  'pg1001nz.db.pgol.',
            :Type => 'CNAME',
            :Ttl => 60,
            :Values => ['sy1-db1.internal.myobpayglobal.com']
          }
        ]
      }
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},        
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone, a role and a loadbalancer' do
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
                },
                "loadbalanced_ports" => [ 'https|443=>443']
            }
        },
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group5,
            security_group_rules5,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers2,
            rds_subnet_group1,
            rds1,
            launch_configuration2,
            autoscaling_group3,
            route53_record_set1,
            deployment_group1,
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone, a role and some more complex networking rules and a deployment group' do
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
                "deploy" => {
                  "group" => "deploy",
                  "application" => "appname",
                },
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group2,
            iam_role3,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone, a role and some more complex networking rules and coalesced security groups' do
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
                ]
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
        {},
        {},
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => true
        }
    ).and_return(
        [
            vpc1,
            routetable1,
            subnets1,
            security_group4,
            security_group_rules4,
            internet_gateway1,
            nat_gateway1,
            route_table_routes1,
            load_balancers1,
            rds_subnet_group6,
            rds3,
            launch_configuration4,
            autoscaling_group2,
            route53_record_set1,
            deployment_group1,
            iam_role2,
            iam_policies_1,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone and a role with an IAM Policy' do
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
                },
                'policies' => ['admin_policy']
            }
        },
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {},
        {
          'admin_policy' => {
            'Effect' => 'Allow',
            'Action' => '*',
            'Resource' => '*'
          }
        },
        {},
        {},
        {},
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set1,
            deployment_group1,
            iam_role4,
            iam_policies_2,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end

  context 'creating an environment with a public zone and route53 record sets' do
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
                },
                'policies' => ['admin_policy']
            }
        },
        {},
        {},
        {
            'Environment' => 'demo'
        },
        {},
        {
          'admin_policy' => {
            'Effect' => 'Allow',
            'Action' => '*',
            'Resource' => '*'
          }
        },
        {},
        {
          'PG1000NZ.fs.pgol.' => {
            'hosted_zone' => 'fs.pgol',
            'type' => 'CNAME',
            'ttl' => 60,
            'value' => 'sy1-db1.internal.myobpayglobal.com'
          },
          'PG1000NZ.db.pgol.' => {
            'hosted_zone' => 'db.pgol',
            'type' => 'CNAME',
            'ttl' => 60,
            'value' => 'sy1-db1.internal.myobpayglobal.com'
          },
          'PG1001NZ.fs.pgol.' => {
            'hosted_zone' => 'fs.pgol',
            'type' => 'CNAME',
            'ttl' => 60,
            'value' => 'sy1-db1.internal.myobpayglobal.com'
          },
          'PG1001NZ.db.pgol.' => {
            'hosted_zone' => 'db.pgol',
            'type' => 'CNAME',
            'ttl' => 60,
            'value' => 'sy1-db1.internal.myobpayglobal.com'
          }
        },
        {
          'filesystem_domain' => 'fs.pgol',
          'database_domain' => 'db.pgol'
        },
        {
            'coalesce_sg_per_role' => false
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
            route53_record_set2,
            deployment_group1,
            iam_role4,
            iam_policies_2,
            iam_instance_profile2,
            s3_bucket1,
            s3_key1
        ])
    }
  end
end

