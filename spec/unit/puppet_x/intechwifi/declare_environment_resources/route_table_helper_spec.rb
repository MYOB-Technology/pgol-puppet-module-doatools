require 'spec_helper'
require 'puppet_x/intechwifi/declare_environment_resources'

describe 'PuppetX::IntechWIFI::Declare_Environment_Resources::RouteHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::Declare_Environment_Resources::RouteTableHelpers }

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
            'ipaddr_weighting' => 4,
            'nat_ipaddr' => '148.88.8.1'
        }
    }
  }

  let(:zones3) {
    {
        'public' => {
            'ipaddr_weighting' => 1
        },
        'nat' => {
            'ipaddr_weighting' => 4,
            'nat_ipaddr' => [
                '148.88.8.1',
                '148.88.8.2',
                '148.88.8.3',
            ],
        },
        'private' => {
            'ipaddr_weighting' => 1
        },
    }
  }

  let(:scratch1) {
    {
        :public_zone? => true,
        :nat_zone? => false,
        :private_zone? => false,
        :nat_list =>[],
        :label_subnet => '%{vpc}%{zone}%{az}',
        :label_routetable => '%{vpc}%{zone}%{az}',
        :label_zone_literals => { 'private' => 'private', 'nat' => 'nat', 'public' => 'public'}
    }
  }


  let(:scratch2) {
    {
        :public_zone? => true,
        :nat_zone? => true,
        :private_zone? => false,
        :nat_list =>[ '148.88.8.1' ],
        :label_subnet => '%{vpc}%{zone}%{az}',
        :label_routetable => '%{vpc}%{zone}%{az}',
        :label_zone_literals => { 'private' => 'private', 'nat' => 'nat', 'public' => 'public'}
    }
  }

  let(:scratch3) {
    {
        :public_zone? => true,
        :nat_zone? => true,
        :private_zone? => true,
        :nat_list =>[
            '148.88.8.1',
            '148.88.8.2',
            '148.88.8.3',
        ],
        :label_subnet => '%{vpc}%{zone}%{az}',
        :label_routetable => '%{vpc}%{zone}%{az}',
        :label_zone_literals => { 'private' => 'private', 'nat' => 'nat', 'public' => 'public'}
    }
  }



  describe 'self.CalculateRouteTablesRequired' do


    it 'for a public only network, there should only be one route table' do
      expect(helpers.CalculateRouteTablesRequired('demo', network1, zones1, scratch1))
          .to eq([{
                      :name => 'demopublicall',
                      :zone => 'public',
                      :az => nil
                  }])
      expect(helpers.CalculateRouteTablesRequired('demo', network2, zones1, scratch1))
          .to eq([{
                      :name => 'demopublicall',
                      :zone => 'public',
                      :az => nil
                  }])
    end

    it 'for a public and nat network, we should have route tables for the nat networks' do
      expect(helpers.CalculateRouteTablesRequired('demo', network1, zones2, scratch2))
          .to eq([{
                      :name => 'demopublicall',
                      :zone => 'public',
                      :az => nil
                  },
                  {
                      :name => 'demonata',
                      :zone => 'nat',
                      :az => 'a'
                  }])
      expect(helpers.CalculateRouteTablesRequired('demo', network2, zones3, scratch3))
          .to eq([{
                      :name => 'demopublicall',
                      :zone => 'public',
                      :az => nil
                  },
                  {
                      :name => 'demonata',
                      :zone => 'nat',
                      :az => 'a'
                  },
                  {
                      :name => 'demonatb',
                      :zone => 'nat',
                      :az => 'b'
                  },
                  {
                      :name => 'demonatc',
                      :zone => 'nat',
                      :az => 'c'
                  },
                  {
                      :name => 'demoprivateall',
                      :zone => 'private',
                      :az => nil
                  }])

    end



  end



  describe 'self.CalculateRoutes' do

    let(:rtdata1) {
      {
          :name => 'demo',
          :zone => 'public',
          :az => nil
      }
    }

    let(:rtdata2) {
      {
          :name => 'demonata',
          :zone => 'nat',
          :az => 'a'
      }
    }

    let(:rtdata3) {
      {
          :name => 'demoprivate',
          :zone => 'private',
          :az => nil
      }
    }

    it("calculate public routes") do
      expect(helpers.CalculateRoutes("demo", network1, zones1, scratch1, rtdata1))
          .to eq([
                     "0.0.0.0/0|igw|demo"
                 ])
    end

    it("calculate nat routes") do
      expect(helpers.CalculateRoutes("demo", network1, zones2, scratch2, rtdata2))
          .to eq([
                     "0.0.0.0/0|nat|demonata"
                 ])
    end

    it("calculate private routes") do
      expect(helpers.CalculateRoutes("demo", network1, zones3, scratch3, rtdata3))
          .to eq([ ])
    end

  end
end
