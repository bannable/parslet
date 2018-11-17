# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Sequence do
  include Parslet

  let(:sequence) { described_class.new }

  describe '>> shortcut' do
    let(:sequence) { str('a') >> str('b') }

    context 'when chained with different atoms' do
      before(:each) do
        # Chain something else to the sequence parslet. If it modifies the
        # parslet atom in place, we'll notice:

        sequence >> str('d')
      end
      let!(:chained) { sequence >> str('c') }

      it 'is side-effect free' do
        expect(chained).to parse('abc')
        expect(chained).not_to parse('abdc')
      end
    end
  end
end
