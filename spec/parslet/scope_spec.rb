# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Scope do
  let(:scope) { described_class.new }

  describe 'simple store/retrieve' do
    before(:each) { scope[:foo] = :bar }
    it 'allows storing objects' do
      scope[:obj] = 42
    end
    it 'raises on access of empty slots' do
      expect do
        scope[:empty]
      end.to raise_error(Parslet::Scope::NotFound)
    end
    it 'allows retrieval of stored values' do
      expect(scope[:foo]).to eq(:bar)
    end
  end

  describe 'scoping' do
    before(:each) { scope[:depth] = 1 }
    before(:each) { scope.push }

    let(:depth) { scope[:depth] }
    subject { depth }

    it { is_expected.to eq(1) }
    describe 'after a push' do
      before(:each) { scope.push }
      it { is_expected.to eq(1) }

      describe 'and reassign' do
        before(:each) { scope[:depth] = 2 }

        it { is_expected.to eq(2) }

        describe 'and a pop' do
          before(:each) { scope.pop }
          it { is_expected.to eq(1) }
        end
      end
    end
  end
end
