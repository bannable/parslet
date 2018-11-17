# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Scope do
  include Parslet
  include Parslet::Atoms::DSL

  let(:context) { Parslet::Atoms::Context.new(nil) }
  let(:captures) { context.captures }

  def inject(string, parser)
    source = Parslet::Source.new(string)
    parser.apply(source, context, true)
  end

  let(:aabb) do
    scope do
      match['ab'].capture(:f) >> dynamic { |_s, c| str(c.captures[:f]) }
    end
  end
  it 'keeps values of captures outside' do
    captures[:f] = 'old_value'
    inject 'aa', aabb
    expect(captures[:f]).to eq('old_value')
  end
end
