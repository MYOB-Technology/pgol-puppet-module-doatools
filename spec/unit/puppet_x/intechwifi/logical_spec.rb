require 'spec_helper'
require 'puppet_x/intechwifi/logical'

describe 'PuppetX::IntechWIFI::Logical' do
  let(:helpers) { PuppetX::IntechWIFI::Logical }

  describe 'array_of_hashes_equal?' do
    it 'matches two empty arrays' do
      expect(helpers.array_of_hashes_equal?([], [])).to eq(true)
    end

    it 'can differentiate between an empty array and an array with a single empty hash' do
      expect(helpers.array_of_hashes_equal?([{}], [])).to eq(false)
    end

    it 'can differentiate between an empty array and an array with a single empty hash' do
      expect(helpers.array_of_hashes_equal?([{"data"=>"test"}], [])).to eq(false)
    end


  end
end
