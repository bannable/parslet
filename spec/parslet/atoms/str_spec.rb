# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Str do
  def str(s)
    described_class.new(s)
  end

  describe 'regression #1: multibyte characters' do
    it 'parses successfully (length check works)' do
      expect(str('あああ')).to parse('あああ')
    end
  end
end
