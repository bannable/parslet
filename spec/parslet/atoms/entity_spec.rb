# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Atoms::Entity do
  context "when constructed with str('bar') inside" do
    let(:named) { Parslet::Atoms::Entity.new('name', &proc { Parslet.str('bar') }) }

    it "should parse 'bar' without raising exceptions" do
      named.parse('bar')
    end
    it "should raise when applied to 'foo'" do
      expect {
        named.parse('foo')
      }.to raise_error(Parslet::ParseFailed)
    end

    describe '#inspect' do
      it 'should return the name of the entity' do
        expect(named.inspect).to eq('NAME')
      end
    end
  end
  context 'when constructed with empty block' do
    let(:entity) { Parslet::Atoms::Entity.new('name', &proc {}) }

    it 'should raise NotImplementedError' do
      expect {
        entity.parse('some_string')
      }.to raise_error(NotImplementedError)
    end
  end

  context 'recursive definition parser' do
    class RecDefParser
      include Parslet
      rule :recdef do
        str('(') >> atom >> str(')')
      end
      rule :atom do
        str('a') | str('b') | recdef
      end
    end
    let(:parser) { RecDefParser.new }

    it 'should parse balanced parens' do
      parser.recdef.parse('(((a)))')
    end
    it "should not throw 'stack level too deep' when printing errors" do
      cause = catch_failed_parse { parser.recdef.parse('(((a))') }
      cause.ascii_tree
    end
  end

  context 'when constructed with a label' do
    let(:named) { Parslet::Atoms::Entity.new('name', 'label', &proc { Parslet.str('bar') }) }

    it "should parse 'bar' without raising exceptions" do
      named.parse('bar')
    end
    it "should raise when applied to 'foo'" do
      expect {
        named.parse('foo')
      }.to raise_error(Parslet::ParseFailed)
    end

    describe '#inspect' do
      it 'should return the label of the entity' do
        expect(named.inspect).to eq('label')
      end
    end

    describe '#parslet' do
      it 'should set the label on the cached parslet' do
        expect(named.parslet.label).to eq('label')
      end
    end
  end
end
