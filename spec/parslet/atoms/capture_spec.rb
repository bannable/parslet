# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Capture do
  include Parslet

  let(:context) { Parslet::Atoms::Context.new(nil) }

  def inject(string, parser)
    source = Parslet::Source.new(string)
    parser.apply(source, context, true)
  end

  it 'should capture simple results' do
    inject 'a', str('a').capture(:a)
    expect(context.captures[:a]).to eq('a')
  end
  it 'should capture complex results' do
    inject 'a', str('a').as(:b).capture(:a)
    expect(context.captures[:a]).to eq({ b: 'a' })
  end
end
