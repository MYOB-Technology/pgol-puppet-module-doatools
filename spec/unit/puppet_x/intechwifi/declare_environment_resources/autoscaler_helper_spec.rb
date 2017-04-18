require 'spec_helper'
require 'puppet_x/intechwifi/declare_environment_resources'

describe 'PuppetX::IntechWIFI::Declare_Environment_Resources::AutoScalerHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::Declare_Environment_Resources::AutoScalerHelper }

  describe 'GetDefaultScaling' do
    it 'returns a min size of 0' do
      expect(helpers.GetDefaultScaling()['min']).to eq(0)
    end
    it 'returns a desired size of 2' do
      expect(helpers.GetDefaultScaling()['desired']).to eq(2)
    end
    it 'returns a max size of 2' do
      expect(helpers.GetDefaultScaling()['max']).to eq(2)
    end
  end

  describe 'CopyScalingValues' do
    it 'copies the min value' do
      expect(helpers.CopyScalingValues({'min' => 5})['min']).to eq(5)
    end
    it 'copies the max value' do
      expect(helpers.CopyScalingValues({'max' => 5})['max']).to eq(5)
    end
    it 'copies the desired value' do
      expect(helpers.CopyScalingValues({'desired' => 5})['desired']).to eq(5)
    end
    it 'does not copy value fred' do
      expect(helpers.CopyScalingValues({'fred' => 5}).has_key?('fred')).to eq(false)
    end
  end
end
