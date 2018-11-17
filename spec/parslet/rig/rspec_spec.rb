# frozen_string_literal: true

require 'spec_helper'
require 'parslet/rig/rspec'

describe 'rspec integration' do
  include Parslet
  subject { str('example') }

  it { is_expected.to parse('example') }
  it { is_expected.not_to parse('foo') }
  it { is_expected.to parse('example').as('example') }
  it { is_expected.not_to parse('foo').as('example') }
  it { is_expected.not_to parse('example').as('foo') }

  it { expect(str('foo').as(:bar)).to parse('foo').as(bar: 'foo') }
  it { expect(str('foo').as(:bar)).not_to parse('foo').as(b: 'f') }

  it 'accepts a block to assert more specific details about the parsing output' do
    expect(str('foo').as(:bar)).to(parse('foo').as do |output|
      expect(output).to have_key(:bar)
      expect(output.values.first).to eq('foo')
    end)
  end

  # Uncomment to test error messages manually:
  # it { str('foo').should parse('foo', :trace => true).as('bar') }
  # it { str('foo').should parse('food', :trace => true) }
  # it { str('foo').should_not parse('foo', :trace => true).as('foo') }
  # it { str('foo').should_not parse('foo', :trace => true) }
  # it 'accepts a block to assert more specific details about the parsing output' do
  #   str('foo').as(:bar).should(parse('foo', :trace => true).as { |output|
  #     output.should_not have_key(:bar)
  #   })
  # end
end

describe 'rspec3 syntax' do
  include Parslet

  let(:s) { str('example') }

  it { expect(s).to parse('example') }
  it { expect(s).not_to parse('foo') }
  it { expect(s).to parse('example').as('example') }
  it { expect(s).not_to parse('foo').as('example') }

  it { expect(s).not_to parse('example').as('foo') }

  # Uncomment to test error messages manually:
  # it { expect(str('foo')).to parse('foo', :trace => true).as('bar') }
  # it { expect(str('foo')).to parse('food', :trace => true) }
  # it { expect(str('foo')).not_to parse('foo', :trace => true).as('foo') }
  # it { expect(str('foo')).not_to parse('foo', :trace => true) }
end
