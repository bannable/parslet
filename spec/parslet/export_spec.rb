# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Parser, 'exporting to other lingos' do
  class MiniLisp < Parslet::Parser
    root :expression
    rule(:expression) do
      space? >> str('(') >> space? >> body >> str(')')
    end

    rule(:body) do
      (expression | identifier | float | integer | string).repeat.as(:exp)
    end

    rule(:space) do
      match('\s').repeat(1)
    end
    rule(:space?) do
      space.maybe
    end

    rule(:identifier) do
      (match('[a-zA-Z=*]') >> match('[a-zA-Z=*_]').repeat).as(:identifier) >> space?
    end

    rule(:float) do
      (
        integer >> (
          str('.') >> match('[0-9]').repeat(1) |
          str('e') >> match('[0-9]').repeat(1)
        ).as(:e)
      ).as(:float) >> space?
    end

    rule(:integer) do
      ((str('+') | str('-')).maybe >> match('[0-9]').repeat(1)).as(:integer) >> space?
    end

    rule(:string) do
      str('"') >> (
        str('\\') >> any |
        str('"').absent? >> any
      ).repeat.as(:string) >> str('"') >> space?
    end
  end

  # I only update the files once I've verified the new syntax to work with
  # the respective tools. This is more an acceptance test than a real spec.

  describe '<- #to_citrus' do
    let(:citrus) do
      File.read(
        File.join(File.dirname(__FILE__), 'minilisp.citrus')
      )
    end
    it 'should be valid citrus syntax' do
      # puts MiniLisp.new.to_citrus
      MiniLisp.new.to_citrus.should == citrus
    end
  end
  describe '<- #to_treetop' do
    let(:treetop) do
      File.read(
        File.join(File.dirname(__FILE__), 'minilisp.tt')
      )
    end
    it 'should be valid treetop syntax' do
      # puts MiniLisp.new.to_treetop
      MiniLisp.new.to_treetop.should == treetop
    end
  end
end
