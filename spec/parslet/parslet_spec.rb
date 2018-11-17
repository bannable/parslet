# frozen_string_literal: true

require 'spec_helper'

describe Parslet do
  include Parslet

  describe Parslet::ParseFailed do
    it 'should be caught by an empty rescue' do
      raise Parslet::ParseFailed
    rescue StandardError
      # Success! Ignore this.
    end
  end
  describe '<- .rule' do
    # Rules define methods. This can be easily tested by defining them right
    # here.
    context 'empty rule' do
      rule(:empty) {}

      it 'should raise a NotImplementedError' do
        expect {
          empty.parslet
        }.to raise_error(NotImplementedError)
      end
    end

    context "containing 'any'" do
      rule(:any_rule) { any }
      subject { any_rule }

      it { is_expected.to be_a Parslet::Atoms::Entity }
      it 'should memoize the returned instance' do
        expect(any_rule.object_id).to eq(any_rule.object_id)
      end
    end
  end
end
