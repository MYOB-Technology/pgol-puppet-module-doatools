require 'spec_helper'
require 'puppet_x/intechwifi/role_helpers'

describe 'PuppetX::IntechWIFI::RoleHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::RoleHelpers }

  name = 'Demo'

  scratch = { :label_security_group => '%{vpc}_%{role}' }

  roles = {
    'role1' => {
      'services' => ['service1', 'service2', 'service3']
    },
    'role2' => {
      'services' => ['service2', 'service3']
    },
    'role3' => {
      'services' => ['service4']
    }
  }

  services = {
    'service1' => {
      'network' => {
        'in' => ['tcp|22|cidr|0.0.0.0/0', 'tcp|80|rss|elb'], 
        'out' => ['tcp|80|cidr|0.0.0.0/0', 'tcp|443|cidr|0.0.0.0/0', 'tcp|3306|rds|testdb']
      }
    }, 
    'service2' => {
      'network' => {
        'in' => ['tcp|22|cidr|0.0.0.0/0', 'tcp|80|rss|elb'], 
        'out' => ['tcp|80|cidr|0.0.0.0/0', 'tcp|443|cidr|0.0.0.0/0', 'tcp|3306|rds|testdb']
      }
    }, 
    'service3' => {
      'network' => {
        'in' => ['tcp|22|cidr|0.0.0.0/0', 'tcp|80|rss|elb'], 
        'out' => ['tcp|80|cidr|0.0.0.0/0', 'tcp|443|cidr|0.0.0.0/0', 'tcp|3306|rds|testdb']
      }
    }, 
    'service4' => {}
  }

  network_rules = [
    {
      :in => [ 
        'tcp|22|cidr|0.0.0.0/0',
        'tcp|80|sg|Demo_role1_elb',
        'tcp|80|sg|Demo_role2_elb'
      ],
      :name => 'Demo_role1',
      :out => [ 
        'tcp|80|cidr|0.0.0.0/0',
        'tcp|443|cidr|0.0.0.0/0',
        'tcp|3306|sg|Demo_testdb'
      ]
    },
    {
      :in => [
        'tcp|22|cidr|0.0.0.0/0',
        'tcp|80|sg|Demo_role1_elb',
        'tcp|80|sg|Demo_role2_elb'
      ],
      :name=>'Demo_role2',
      :out=> [
        'tcp|80|cidr|0.0.0.0/0',
        'tcp|443|cidr|0.0.0.0/0',
        'tcp|3306|sg|Demo_testdb'
      ]
    }
  ]

  security_groups = [
    {'description'=>'Role security group', 'name'=>'Demo_role1'},
    {'description'=>'Role security group', 'name'=>'Demo_role2'}
  ]

  describe '#calculate_security_groups' do
    it 'returns an array of roles that will have network rules attached to them' do
      expect(helpers.calculate_security_groups(name, roles, services, scratch)).to eq(security_groups)
    end
  end

  describe '#calculate_network_rules' do
    it 'returns an array of roles that will have network rules attached to them' do
      expect(helpers.calculate_network_rules(name, roles, services, scratch)).to eq(network_rules)
    end
  end
end
