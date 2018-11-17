# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::DSL do
  describe 'deprecated methods' do
    let(:parslet) { Parslet.str('foo') }
    describe '<- #absnt?' do
      slet(:absnt) { parslet.absnt? }
      it '#bound_parslet' do
        expect(absnt.bound_parslet).to eq(parslet)
      end
      it 'should be a negative lookahead' do
        expect(absnt.positive).to eq(false)
      end
    end
    describe '<- #prsnt?' do
      slet(:prsnt) { parslet.prsnt? }
      it '#bound_parslet' do
        expect(prsnt.bound_parslet).to eq(parslet)
      end
      it 'should be a positive lookahead' do
        expect(prsnt.positive).to eq(true)
      end
    end
  end
end
