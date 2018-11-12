require 'spec_helper'
require 'puppet_x/intechwifi/logical'

describe 'PuppetX::IntechWIFI::Tags_Property' do
    let(:helpers) { PuppetX::IntechWIFI::Tags_Property }
    describe 'insync?' do
        it 'matches two empty hashes' do
            expect(helpers.insync?({},{})).to eq(true)
        end
    end

    describe 'insync?' do
        it 'matches an identical hashes' do
            expect(helpers.insync?(
                { "name" => "fred", "age" => "42"},
                { "name" => "fred", "age" => "42"}
            )).to eq(true)
        end
    end

    describe 'insync?' do
        it 'order of keys does not matter' do
            expect(helpers.insync?(
                { "name" => "fred", "age" => "42"},
                { "age" => "42", "name" => "fred"}
            )).to eq(true)
        end
    end

    describe 'insync?' do
        it 'Does not match if keys have different cases' do
            expect(helpers.insync?(
                { "name" => "fred", "age" => "42"},
                { "Name" => "fred", "Age" => "42"}
            )).to eq(false)
        end
    end

end
