require 'spec_helper'
require 'puppet_x/intechwifi/declare_environment_resources/autoscaling_group_helpers'

describe 'PuppetX::IntechWIFI::DeclareEnvironmentResources::AutoscalingGroupHelpers' do
  let(:helpers) { PuppetX::IntechWIFI::DeclareEnvironmentResources::AutoscalingGroupHelpers }

  describe '#get_default_scaling' do
    it 'returns a min size of 0' do
      expect(helpers.get_default_scaling()['min']).to eq(0)
    end
    it 'returns a desired size of 2' do
      expect(helpers.get_default_scaling()['desired']).to eq(2)
    end
    it 'returns a max size of 2' do
      expect(helpers.get_default_scaling()['max']).to eq(2)
    end
  end

  describe '#copy_scaling_values' do
    it 'copies the min value' do
      expect(helpers.copy_scaling_values({'min' => 5})['min']).to eq(5)
    end
    it 'copies the max value' do
      expect(helpers.copy_scaling_values({'max' => 5})['max']).to eq(5)
    end
    it 'copies the desired value' do
      expect(helpers.copy_scaling_values({'desired' => 5})['desired']).to eq(5)
    end
    it 'does not copy value fred' do
      expect(helpers.copy_scaling_values({'fred' => 5}).has_key?('fred')).to eq(false)
    end
  end
end
