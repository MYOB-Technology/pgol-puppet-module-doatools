require 'spec_helper'
require 'puppet_x/intechwifi/declare_environment_resources'

describe 'PuppetX::IntechWIFI::Declare_Environment_Resources::AutoScalerHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::Declare_Environment_Resources::LoadBalancerHelper }

  services_1 = {
      'service_1' => {
          'loadbalanced_ports' => [
              '{http,80}=>80',
              '{https,443,cert_arn}=>80',
          ],
      },
      'service_2' => {
      },
      'service_3' => {
          'loadbalanced_ports' => [
          ],
      },
  }


  describe "DoesServiceHaveLoadbalancedPorts" do
    it "returns false when the service is not defined." do
      expect(helpers.DoesServiceHaveLoadbalancedPorts(services_1, 'service_0')).to eq(false)
    end

    it "returns false when the service does not have loadbalanced_ports defined." do
      expect(helpers.DoesServiceHaveLoadbalancedPorts(services_1, 'service_2')).to eq(false)
    end

    it "returns false when the service loadbalanced_ports are empty" do
      expect(helpers.DoesServiceHaveLoadbalancedPorts(services_1, 'service_3')).to eq(false)
    end

    it "returns true when the service has some load balanced ports defined" do
      expect(helpers.DoesServiceHaveLoadbalancedPorts(services_1, 'service_1')).to eq(true)
    end

  end

  services_2 = {
      'service_1' => {
          'loadbalanced_ports' => [
              '{http,80}=>80',
              '{https,443,cert_arn}=>80',
          ],
      },
      'service_2' => {
          'loadbalanced_ports' => [
              '{http,80}=>80',
          ],
      },
      'service_3' => {
          'loadbalanced_ports' => [
          ],
      },
  }

  services_3 = {
      'service_1' => {
          'loadbalanced_ports' => [
          ],
      },
      'service_2' => {
          'loadbalanced_ports' => [
          ],
      },
      'service_3' => {
          'loadbalanced_ports' => [
          ],
      },
  }

  roles_0 = {

  }

  roles_1 = {
      'role_name_1' => {
      },
  }

  roles_2 = {
      'role_name_1' => {
          'services' => [
          ],
      },
      'role_name_2' => {
          'services' => [
          ],
      },
      'role_name_3' => {
          'services' => [
          ],
      },
      'role_name_4' => {
          'services' => [
          ],
      },
  }

  roles_3 = {
      'role_name_1' => {
          'services' => [
              'service_1',
          ],
      },
      'role_name_2' => {
          'services' => [
              'service_1',
              'service_2',
          ],
      },
      'role_name_3' => {
          'services' => [
              'service_3',
          ],
      },
      'role_name_4' => {
          'services' => [
              'service_2',
              'service_3'
          ],
      },
  }

  describe "GetRolesWithLoadBalancers" do
    it "returns an empty list if there are no roles" do
      expect(helpers.GetRoleNamesWithLoadBalancers(roles_0, services_1)).to eq([])
    end

    it "returns an empty list if the role has no services" do
      expect(helpers.GetRoleNamesWithLoadBalancers(roles_1, services_1)).to eq([])
    end

    it "returns an empty list if all roles have no services" do
      expect(helpers.GetRoleNamesWithLoadBalancers(roles_2, services_1)).to eq([])
    end

    it "returns an empty list if all roles have only have services that do not have load balanced ports" do
      expect(helpers.GetRoleNamesWithLoadBalancers(roles_3, services_3)).to eq([])
    end

    it "returns a list of roles containing only the roles that have load balanced ports" do
      expect(helpers.GetRoleNamesWithLoadBalancers(roles_3, services_2)).to eq(['role_name_1', 'role_name_2', 'role_name_4'])
    end

  end

  describe "GenerateServicesWithLoadBalancedPortsByRoleHash" do
    it "returns an empty hash if there are no roles" do
      expect(helpers.GenerateServicesWithLoadBalancedPortsByRoleHash(roles_0, services_1)).to eq({})
    end

    it "returns an empty hash if the roles have no services" do
      expect(helpers.GenerateServicesWithLoadBalancedPortsByRoleHash(roles_1, services_1)).to eq({})
    end

    it "returns an empty hash if all roles have no services" do
      expect(helpers.GenerateServicesWithLoadBalancedPortsByRoleHash(roles_2, services_1)).to eq({})
    end

    it "returns an empty hash if all roles have only have services that do not have load balanced ports" do
      expect(helpers.GenerateServicesWithLoadBalancedPortsByRoleHash(roles_3, services_3)).to eq({})
    end

    it "returns a hash that enables lookups by role to a list of services that have load balanced ports" do
      expect(
          helpers.GenerateServicesWithLoadBalancedPortsByRoleHash(roles_3, services_2)
      ).to eq({
         "role_name_1" => [{"loadbalanced_ports"=>["{http,80}=>80", "{https,443,cert_arn}=>80"], "service_name"=>"service_1"}],
         "role_name_2" => [{"loadbalanced_ports"=>["{http,80}=>80", "{https,443,cert_arn}=>80"], "service_name"=>"service_1"}, {"loadbalanced_ports"=>["{http,80}=>80"], "service_name"=>"service_2"}],
         "role_name_4" => [{"loadbalanced_ports"=>["{http,80}=>80"], "service_name"=>"service_2"}],
              })
    end
  end

  describe "ParseSharedPort" do
    it "handles a http example properly" do
      expect(
          helpers.ParseSharedPort("http|80=>80")
      ).to eq({
          :protocol => 'http',
          :listen_port => '80',
          :target_port => '80'
              })
    end

  end
end
