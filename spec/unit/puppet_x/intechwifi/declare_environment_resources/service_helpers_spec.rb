require 'spec_helper'
require 'puppet_x/intechwifi/service_helpers'

describe 'PuppetX::IntechWIFI::ServiceHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::ServiceHelpers }

  name = 'Demo'

  scratch = { :label_security_group => '%{vpc}_%{role}' }

  roles = {
    'role1' => {
      'services' => ['service1', 'service2', 'sevice3']
    },
    'role2' => {
      'services' => ['service2', 'sevice3']
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

  role_security_groups = {
    'Demo_role1' => { :in => [], :out => [] }, 
    'Demo_role2' => { :in => [], :out => [] }
  }

  describe '#calculate_role_security_groups' do
    it 'returns an array of roles that will have network rules attached to them' do
      expect(helpers.calculate_role_security_groups(name, roles, services, scratch)).to eq(role_security_groups)
    end
  end
end
