# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Ignored do
  include Parslet

  describe 'ignore' do
    it 'ignores parts of the input' do
      expect(str('a').ignore.parse('a')).to be_nil
      expect((str('a') >> str('b').ignore >> str('c')).parse('abc')).to eq('ac')
      expect((str('a') >> str('b').as(:name).ignore >> str('c')).parse('abc')).to eq('ac')
      expect((str('a') >> str('b').maybe.ignore >> str('c')).parse('abc')).to eq('ac')
      expect((str('a') >> str('b').maybe.ignore >> str('c')).parse('ac')).to eq('ac')
    end
  end
end
