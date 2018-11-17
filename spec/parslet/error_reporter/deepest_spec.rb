# frozen_string_literal: true

require 'spec_helper'

describe Parslet::ErrorReporter::Deepest do
  let(:reporter) { described_class.new }
  let(:fake_source) { flexmock('source') }

  describe '#err' do
    before(:each) do
      fake_source.should_receive(
        pos: 13,
        line_and_column: [1, 1]
      )
    end

    it 'returns the deepest cause' do
      flexmock(reporter)
        .should_receive(:deepest).and_return(:deepest)
      expect(reporter.err('parslet', fake_source, 'message'))
              .to eq(:deepest)
    end
  end
  describe '#err_at' do
    before(:each) do
      fake_source.should_receive(
        pos: 13,
        line_and_column: [1, 1]
      )
    end

    it 'returns the deepest cause' do
      flexmock(reporter)
        .should_receive(:deepest).and_return(:deepest)
      expect(reporter.err('parslet', fake_source, 'message', 13))
              .to eq(:deepest)
    end
  end
  describe '#deepest(cause)' do
    def fake_cause(pos = 13, children = nil)
      flexmock('cause' + pos.to_s, pos: pos, children: children)
    end

    context 'when there is no deepest cause yet' do
      let(:cause) { fake_cause }
      it 'returns the given cause' do
        expect(reporter.deepest(cause)).to eq(cause)
      end
    end
    context 'when the previous cause is deeper (no relationship)' do
      let(:previous) { fake_cause }
      before(:each) do
        reporter.deepest(previous)
      end

      it 'returns the previous cause' do
        expect(reporter.deepest(fake_cause(12)))
                .to eq(previous)
      end
    end
    context 'when the previous cause is deeper (child)' do
      let(:previous) { fake_cause }
      before(:each) do
        reporter.deepest(previous)
      end

      it 'returns the given cause' do
        given = fake_cause(12, [previous])
        expect(reporter.deepest(given)).to eq(given)
      end
    end
    context 'when the previous cause is shallower' do
      before(:each) do
        reporter.deepest(fake_cause)
      end

      it 'stores the cause as deepest' do
        deeper = fake_cause(14)
        reporter.deepest(deeper)
        expect(reporter.deepest_cause).to eq(deeper)
      end
    end
  end
end
