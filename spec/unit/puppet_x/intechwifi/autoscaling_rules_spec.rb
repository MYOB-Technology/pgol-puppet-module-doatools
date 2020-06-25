require 'spec_helper'
require 'puppet_x/intechwifi/autoscaling_rules'

describe 'PuppetX::IntechWIFI::AutoScalingRules' do
  let (:helpers) { PuppetX::IntechWIFI::Autoscaling_Rules }
  
  charset="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  describe 'extract_code_value' do
    it 'decodes each char correctly' do
      chars = charset.split('')
      chars.each {|c| 
        # puts "Actual value: #{charset.index(c)}, calculated value: #{helpers.extract_code_value(c)}"
        expect(helpers.extract_code_value c).to eq(charset.index(c))
      }
    end
  end

  describe 'encode_code_value' do
    it 'encodes each ordinal correctly' do
      ordinal = 0
      chars = charset.split('')
      while ordinal < 62 do
        # puts "Actual value: #{chars[ordinal]}, calculated value: #{helpers.encode_code_value(ordinal)}"
        expect(helpers.encode_code_value(ordinal)).to match(chars[ordinal])
        ordinal += 1
      end
    end
  end

  names = [ 'launchConfig1_=00Y=', 'launchConfig1_=00Z=', 'launchConfig1_=00a=', 'launchConfig_=00z=', 'launchConfig_=010=', 'launchConfig_=011=' ]
  values = [ 34, 35, 36, 61, 62, 63 ]
  indices = [ '_=00Y=', '_=00Z=', '_=00a=', '_=00z=', '_=010=', '_=011=' ]
  numCases = 6  

  describe 'index' do
    it 'can decode indices around wraparounds' do
      i = 0
      while i < numCases do
        expect(helpers.index(names[i])).to eq(values[i])
        i += 1
      end
    end
  end

  describe 'encode_index' do
    it 'can encode ordinals around wraparounds' do 
      i = 0
      while i < numCases do
        expect(helpers.encode_index(values[i])).to eq(indices[i])
        i += 1
      end
    end
  end
end


