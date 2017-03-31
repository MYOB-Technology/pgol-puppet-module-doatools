require 'spec_helper'
describe Puppet::Type.type(:vpc) do
  context "when validating type attributes" do
    [ :name, :region, :cidr,  ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
    [ :dns_hostnames, :dns_resolution, :tags ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end
end

