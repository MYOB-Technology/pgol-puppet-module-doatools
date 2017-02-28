require 'spec_helper'
describe 'doatools::network' do
  let(:title) { 'testvpc' }
  it { is_expected.to contain_vpc('testvpc') }

end

