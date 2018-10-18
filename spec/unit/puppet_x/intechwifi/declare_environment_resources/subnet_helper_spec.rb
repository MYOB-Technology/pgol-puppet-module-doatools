require 'spec_helper'
require 'puppet_x/intechwifi/declare_environment_resources'

describe 'PuppetX::IntechWIFI::Declare_Environment_Resources::SubnetHelper' do
  let(:subnet_helpers) { PuppetX::IntechWIFI::Declare_Environment_Resources::SubnetHelpers }

  describe 'self.CalculateCidrsForNetwork' do
    let(:network1) {
      {
          'cidr' => '192.168.0.0/24',
          'availability' => [ 'a', 'b' ],
      }
    }

    let (:network2) {
      {
          'cidr' => '192.168.0.0/20',
          'availability' => [ 'a', 'b', 'c' ],
      }
    }

    let (:network3) {

    }

    let(:zones1) {
      {
          'public' => {
              'ipaddr_weighting' => 1
          },
      }
    }

    let(:zones2) {
      {
          'public' => {
              'ipaddr_weighting' => 1
          },
          'nat' => {
              'ipaddr_weighting' => 4
          }
      }
    }

    let(:zones3) {
      {
          'public' => {
              'ipaddr_weighting' => 1
          },
          'nat' => {
              'ipaddr_weighting' => 8
          },
          'private' => {
              'ipaddr_weighting' => 9
          },
      }
    }

    let(:scratch) {
      {
        :label_subnet => '%{vpc}%{zone}%{az}'
      }
    }

    it 'should handle standard block sizes' do

      expect(subnet_helpers.CalculateSubnetData("unittest", network1, zones1, scratch))
          .to eq([
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.0.0/25", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.0.128/25", :index=>1, :name=>"unittestpublicb"},
                 ])

      expect(subnet_helpers.CalculateSubnetData("unittest", network1, zones2, scratch))
          .to eq([
                     { :zone=>"nat", :az=>"a", :cidr=>"192.168.0.0/26", :index=>0, :name=>"unittestnata"},
                     { :zone=>"nat", :az=>"b", :cidr=>"192.168.0.64/26", :index=>1, :name=>"unittestnatb"},
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.0.128/28", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.0.144/28", :index=>1, :name=>"unittestpublicb"},
                 ])

      expect(subnet_helpers.CalculateSubnetData("unittest", network1, zones1, scratch))
          .to eq([
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.0.0/25", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.0.128/25", :index=>1, :name=>"unittestpublicb"},
                 ])

      expect(subnet_helpers.CalculateSubnetData("unittest", network2, zones1, scratch))
          .to eq([
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.0.0/22", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.4.0/22", :index=>1, :name=>"unittestpublicb"},
                     { :zone=>"public", :az=>"c", :cidr=>"192.168.8.0/22", :index=>2, :name=>"unittestpublicc"},
                 ])

      expect(subnet_helpers.CalculateSubnetData("unittest", network2, zones2, scratch))
          .to eq([
                     { :zone=>"nat", :az=>"a", :cidr=>"192.168.0.0/22", :index=>0, :name=>"unittestnata"},
                     { :zone=>"nat", :az=>"b", :cidr=>"192.168.4.0/22", :index=>1, :name=>"unittestnatb"},
                     { :zone=>"nat", :az=>"c", :cidr=>"192.168.8.0/22", :index=>2, :name=>"unittestnatc"},
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.12.0/24", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.13.0/24", :index=>1, :name=>"unittestpublicb"},
                     { :zone=>"public", :az=>"c", :cidr=>"192.168.14.0/24", :index=>2, :name=>"unittestpublicc"},
                 ])

      expect(subnet_helpers.CalculateSubnetData("unittest", network2, zones3, scratch))
          .to eq([
                     { :zone=>"private", :az=>"a", :cidr=>"192.168.0.0/23", :index=>0, :name=>"unittestprivatea"},
                     { :zone=>"private", :az=>"b", :cidr=>"192.168.2.0/23", :index=>1, :name=>"unittestprivateb"},
                     { :zone=>"private", :az=>"c", :cidr=>"192.168.4.0/23", :index=>2, :name=>"unittestprivatec"},
                     { :zone=>"nat", :az=>"a", :cidr=>"192.168.6.0/23", :index=>0, :name=>"unittestnata"},
                     { :zone=>"nat", :az=>"b", :cidr=>"192.168.8.0/23", :index=>1, :name=>"unittestnatb"},
                     { :zone=>"nat", :az=>"c", :cidr=>"192.168.10.0/23", :index=>2, :name=>"unittestnatc"},
                     { :zone=>"public", :az=>"a", :cidr=>"192.168.12.0/26", :index=>0, :name=>"unittestpublica"},
                     { :zone=>"public", :az=>"b", :cidr=>"192.168.12.64/26", :index=>1, :name=>"unittestpublicb"},
                     { :zone=>"public", :az=>"c", :cidr=>"192.168.12.128/26", :index=>2, :name=>"unittestpublicc"},
                 ])



    end

    it 'should reject layouts where the subnet cidrs become too small' do
      expect {
        subnet_helpers.CalculateSubnetData("unittest", network1, zones3, scratch)
      }.to raise_exception(PuppetX::IntechWIFI::Declare_Environment_Resources::CidrMaths::CidrSizeTooSmallForSubnet)


    end

  end

  describe 'self.GenerateSubnetResources' do
    let(:network1) {
      {
          'cidr' => "192.168.0.0/24",
          'availability' => [ "a", "b"]
      }
    }

    let(:zones1) {
      {
          'public' => {
              'ipaddr_weighting' => 1
          },
          'nat' => {
              'ipaddr_weighting' => 1
          },
      }
    }

    let (:scratch1) {
      {
          :public_zone? => true,
          :nat_zone? => true,
          :private_zone? => false,
          :nat_list =>[ '148.88.8.1', '148.88.8.2' ],
          :subnet_data => [
              { :zone=>"nat", :az=>"a", :cidr=>"192.168.0.0/26", :index=>0},
              { :zone=>"nat", :az=>"b", :cidr=>"192.168.0.64/26", :index=>1},
              { :zone=>"public", :az=>"a", :cidr=>"192.168.0.128/28", :index=>0},
              { :zone=>"public", :az=>"b", :cidr=>"192.168.0.144/28", :index=>1},
          ],
          :route_table_data => [
              {
                  :name => 'demo',
                  :zone => 'public',
                  :az => nil
              }, {
                 :name => 'demonata',
                 :zone => 'nat',
                 :az => 'a'
              }, {
                 :name => 'demonatb',
                 :zone => 'nat',
                 :az => 'b'
              }],
          :label_subnet => '%{vpc}%{zone}%{az}'
      }
    }

    it 'validate subnets' do
      expect(subnet_helpers.GenerateSubnetResources('demo', 'ensure', 'us-east-1', network1, zones1, scratch1, { 'Environment' => "demo" }))
      .to eq({
                 'resource_type' => "subnet",
                 'resources' => {
                     "demonata" => {
                         :ensure => "ensure",
                         :region => "us-east-1",
                         :vpc => "demo",
                         :availability_zone => "a",
                         :cidr => "192.168.0.0/26",
                         :tags => { 'Environment' => "demo" },
                         :route_table => "demonata",
                         :public_ip => false
                     },
                     "demonatb"=>{
                         :ensure => "ensure",
                         :region => "us-east-1",
                         :vpc => "demo",
                         :availability_zone => "b",
                         :cidr => "192.168.0.64/26",
                         :tags => { 'Environment' => "demo" },
                         :route_table => "demonatb",
                         :public_ip => false
                     },
                     "demopublica" => {
                         :ensure => "ensure",
                         :region => "us-east-1",
                         :vpc => "demo",
                         :availability_zone => "a",
                         :cidr => "192.168.0.128/28",
                         :tags => { 'Environment' => "demo" },
                         :route_table => "demo",
                         :public_ip => true
                     }, "demopublicb" => {
                         :ensure => "ensure",
                         :region => "us-east-1",
                         :vpc => "demo",
                         :availability_zone => "b",
                         :cidr => "192.168.0.144/28",
                         :tags => { 'Environment' => "demo" },
                         :route_table => "demo",
                         :public_ip => true
                     }
                 }
             })
    end
  end

end
