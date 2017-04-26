require 'spec_helper'
describe 'doatools::environment' do
  let(:title) { 'testvpc' }
  it { is_expected.to contain_vpc('testvpc') }

end

