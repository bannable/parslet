# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Position do
  slet(:position) { described_class.new('öäüö', 4) }

  it 'should have a charpos of 2' do
    expect(position.charpos).to eq(2)
  end
  it 'should have a bytepos of 4' do
    expect(position.bytepos).to eq(4)
  end
end
