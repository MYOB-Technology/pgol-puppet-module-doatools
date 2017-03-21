require 'spec_helper'
describe 'doatools' do
  context 'with default values for all parameters' do
    it { should contain_class('doatools') }
  end
end
