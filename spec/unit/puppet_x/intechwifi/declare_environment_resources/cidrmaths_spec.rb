require 'spec_helper'


describe 'PuppetX::IntechWIFI::Declare_Environment_Resources::CidrMaths' do
  let(:cidr_maths) { PuppetX::IntechWIFI::Declare_Environment_Resources::CidrMaths }

  describe 'self.CidrBlockSize' do
    it 'should handle standard block sizes' do
      expect(cidr_maths.IpAddrsInCidrBlock(32)).to eq(1)
      expect(cidr_maths.IpAddrsInCidrBlock(31)).to eq(2)
      expect(cidr_maths.IpAddrsInCidrBlock(30)).to eq(4)
      expect(cidr_maths.IpAddrsInCidrBlock(26)).to eq(64)
      expect(cidr_maths.IpAddrsInCidrBlock(24)).to eq(256)
      expect(cidr_maths.IpAddrsInCidrBlock(16)).to eq(65536)
    end

  end

  describe 'self.LongToCidr' do
    it 'format these numbers to well known IP addresses' do
      base_addr = cidr_maths.CidrToLong('192.168.0.0/24')

      expect(cidr_maths.LongToCidr(base_addr, 24)).to eq("192.168.0.0/24")
      expect(cidr_maths.LongToCidr(base_addr + 1, 32)).to eq("192.168.0.1/32")
      expect(cidr_maths.LongToCidr(base_addr + 256, 24)).to eq("192.168.1.0/24")
      expect(cidr_maths.LongToCidr(base_addr + 512, 23)).to eq("192.168.2.0/23")
    end
  end

  describe 'self.calculate_block_size' do
    it 'single zone, single az...' do
      expect(cidr_maths.CalculateBlockSize(24, 1, 1, 1)).to eq(24)
      expect(cidr_maths.CalculateBlockSize(24, 2, 2, 1)).to eq(24)
      expect(cidr_maths.CalculateBlockSize(24, 3, 3, 1)).to eq(24)
      expect(cidr_maths.CalculateBlockSize(24, 5, 5, 1)).to eq(24)
    end

    it 'single zone, multiple az...' do
      expect(cidr_maths.CalculateBlockSize(24, 1, 1, 2)).to eq(25)
      expect(cidr_maths.CalculateBlockSize(24, 2, 2, 3)).to eq(26)
      expect(cidr_maths.CalculateBlockSize(24, 3, 3, 4)).to eq(26)
      expect(cidr_maths.CalculateBlockSize(24, 5, 5, 5)).to eq(27)
    end

    it 'multiple zone, single az...' do
      expect(cidr_maths.CalculateBlockSize(24, 1, 2, 1)).to eq(25)
      expect(cidr_maths.CalculateBlockSize(24, 2, 4, 1)).to eq(25)
      expect(cidr_maths.CalculateBlockSize(24, 3, 4, 1)).to eq(25)
      expect(cidr_maths.CalculateBlockSize(24, 5, 8, 1)).to eq(25)
      expect(cidr_maths.CalculateBlockSize(24, 5, 17, 1)).to eq(26)
    end

    it 'multiple zone, multiple az...' do
      expect(cidr_maths.CalculateBlockSize(24, 1, 2, 2)).to eq(26)
    end
  end

end
