# frozen_string_literal: true

require 'parslet/atoms/visitor'

module Parslet
  module Accelerator
    # @api private
    class Apply
      def initialize(engine, expr)
        @engine = engine
        @expr = expr
      end

      def visit_parser(_root)
        false
      end

      def visit_entity(_name, _block)
        false
      end

      def visit_named(name, _atom)
        match(:as) do |key|
          @engine.try_bind(key, name)
        end
      end

      def visit_repetition(_tag, min, max, atom)
        match(:rep) do |e_min, e_max, expr|
          e_min == min && e_max == max && @engine.match(atom, expr)
        end
      end

      def visit_alternative(alternatives)
        match(:alt) do |*expressions|
          return false if alternatives.size != expressions.size

          alternatives.zip(expressions).all? do |atom, expr|
            @engine.match(atom, expr)
          end
        end
      end

      def visit_sequence(sequence)
        match(:seq) do |*expressions|
          return false if sequence.size != expressions.size

          sequence.zip(expressions).all? do |atom, expr|
            @engine.match(atom, expr)
          end
        end
      end

      def visit_lookahead(positive, atom)
        match(:absent) do |expr|
          return positive == false && @engine.match(atom, expr)
        end
        match(:present) do |expr|
          return positive == true && @engine.match(atom, expr)
        end
      end

      def visit_re(regexp)
        match(:re) do |*bind_conditions|
          bind_conditions.all? do |bind_cond|
            @engine.try_bind(bind_cond, regexp)
          end
        end
      end

      def visit_str(str)
        match(:str) do |*bind_conditions|
          bind_conditions.all? do |bind_cond|
            @engine.try_bind(bind_cond, str)
          end
        end
      end

      def match(type_tag)
        expr_tag = @expr.type
        yield *@expr.args if expr_tag == type_tag
      end
    end

    # @api private
    class Engine
      attr_reader :bindings

      def initialize
        @bindings = {}
      end

      def match(atom, expr)
        atom.accept(
          Apply.new(self, expr)
        )
      end

      def try_bind(variable, value)
        if bound? variable
          value == lookup(variable)
        else
          case variable
          when Symbol
            bind(variable, value)
          else
            # This does not look like a variable - let's try matching it against
            # the value:
            variable === value
          end
        end
      end

      def bound?(var)
        @bindings.key? var
      end

      def lookup(var)
        @bindings[var]
      end

      def bind(var, val)
        @bindings[var] = val
      end
    end
  end
end
