# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Re do
  describe 'construction' do
    include Parslet

    it 'should allow match(str) form' do
      expect(match('[a]')).to be_a(Parslet::Atoms::Re)
    end
    it 'should allow match[str] form' do
      expect(match['a']).to be_a(Parslet::Atoms::Re)
    end
  end
end
