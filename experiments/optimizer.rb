# frozen_string_literal: true

# Example that demonstrates how a simple erb-like parser could be constructed.

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'parslet'
require 'parslet/atoms/visitor'
require 'parslet/convenience'

class ErbParser < Parslet::Parser
  rule(:ruby) { (str('%>').absent? >> any).repeat.as(:ruby) }

  rule(:expression) { (str('=') >> ruby).as(:expression) }
  rule(:comment) { (str('#') >> ruby).as(:comment) }
  rule(:code) { ruby.as(:code) }
  rule(:erb) { expression | comment | code }

  rule(:erb_with_tags) { str('<%') >> erb >> str('%>') }
  rule(:text) { (str('<%').absent? >> any).repeat(1) }

  rule(:text_with_ruby) { (text.as(:text) | erb_with_tags).repeat.as(:text) }
  root(:text_with_ruby)
end

class Parslet
  class Source
    def match_excluding(str)
      slice_str = @str.check_until(Regexp.new(Regexp.escape(str)))
      return @str.rest_size unless slice_str

      slice_str.size - str.size
    end
  end
end

class AbsentParser < Parslet::Atoms::Base
  def initialize(absent)
    @absent = absent
  end

  def try(source, context, _consume_all)
    excluding_length = source.match_excluding(@absent)
    return succ(source.consume(excluding_length)) if excluding_length >= 1

    context.err(self, source, "Failed absence #{@absent.inspect}.")
  end
end

class Parslet
  class Optimizer
    module DSL
      def >>(other)
        Match::Sequence.new(self, other)
      end

      def absent?
        Match::Lookahead.new(false, self)
      end

      def repeat(min = 0, max = nil)
        Match::Repetition.new(self, min, max)
      end
    end
    module Match
      class Base
        include DSL

        def visit_parser(_root)
          false
        end

        def visit_entity(_name, _block)
          false
        end

        def visit_named(_name, _atom)
          false
        end

        def visit_repetition(_tag, _min, _max, _atom)
          false
        end

        def visit_alternative(_alternatives)
          false
        end

        def visit_sequence(_sequence)
          false
        end

        def visit_lookahead(_positive, _atom)
          false
        end

        def visit_re(_regexp)
          false
        end

        def visit_str(_str)
          false
        end

        def match(other, bindings)
          @bindings = bindings
          other.accept(self)
        end
      end
      class Str < Base
        def initialize(variable)
          @variable = variable
        end

        def visit_str(str)
          bound_value = @bindings[@variable]
          return bound_value == str if bound_value

          @bindings[@variable] = str
          true
        end
      end
      class Lookahead < Base
        def initialize(positive, expression)
          @positive = positive
          @expression = expression
        end

        def visit_lookahead(positive, atom)
          positive == @positive &&
            @expression.match(atom, @bindings)
        end
      end
      class Sequence < Base
        def initialize(*parslets)
          @parslets = parslets
        end

        def visit_sequence(sequence)
          sequence.zip(@parslets).all? { |atom, expr| expr.match(atom, @bindings) }
        end
      end
      class Repetition < Base
        def initialize(expression, min, max)
          @min = min
          @max = max
          @expression = expression
        end

        def visit_repetition(_tag, min, max, atom)
          @min == min && @max == max && @expression.match(atom, @bindings)
        end
      end
      class Re < Base
        def initialize(variable)
          @variable = variable
        end

        def visit_re(regexp)
          case @variable
          when Symbol
            p [@variable, regexp]
            raise
          else
            @variable == regexp
          end
        end
      end
    end

    def self.str(var)
      Match::Str.new(var)
    end

    def self.any
      Match::Re.new('.')
    end

    class Rule
      def initialize(expression, replacement)
        @expression = expression
        @replacement = replacement
      end

      class Context
        def initialize(bindings)
          @bindings = bindings
        end

        def method_missing(sym, *args, &block)
          return @bindings[sym] if args.empty? && !block && @bindings.key?(sym)

          super
        end

        def call(callable)
          instance_eval(&callable)
        end
      end

      def match(other)
        bindings = {}
        return bindings if @expression.match(other, bindings)
      end

      def call(bindings)
        context = Context.new(bindings)
        context.call(@replacement)
      end
    end
    def self.rule(expression, &replacement)
      rules << Rule.new(expression, replacement)
    end

    def self.rules
      @rules ||= []
    end

    def rules
      self.class.rules
    end

    class Transform
      def initialize(rules)
        @rules = rules
        @candidates = []
      end

      def default_parser(root)
        root.accept(self)
      end

      def default_entity(name, block)
        Parslet::Atoms::Entity.new(name) { block.call.accept(self) }
      end

      def default_named(name, atom)
        Parslet::Atoms::Named.new(atom.accept(self), name)
      end

      def default_repetition(tag, min, max, atom)
        Parslet::Atoms::Repetition.new(atom.accept(self), min, max, tag)
      end

      def default_alternative(alternatives)
        Parslet::Atoms::Alternative.new(
          *alternatives.map { |atom| atom.accept(self) }
        )
      end

      def default_sequence(sequence)
        Parslet::Atoms::Sequence.new(
          *sequence.map { |atom| atom.accept(self) }
        )
      end

      def default_lookahead(positive, atom)
        Parslet::Atoms::Lookahead.new(atom, positive)
      end

      def default_re(regexp)
        Parslet::Atoms::Re.new(regexp)
      end

      def default_str(str)
        Parslet::Atoms::Str.new(str)
      end

      def method_missing(sym, *args, &block)
        if (md = sym.to_s.match(/visit_([a-z]+)/)) && !block
          # Obtain the default, which is a completely transformed new parser
          default = send("default_#{md[1]}", *args)
          # Try transforming this parser again at the current level
          return transform(default)
        end

        super
      end

      def transform(atom)
        # Try to match one of the rules against the newly constructed tree.
        @rules.each do |rule|
          bindings = rule.match(atom)
          return rule.call(bindings) if bindings
        end

        # No match, returning new atom.
        atom
      end
    end

    def apply(parser)
      parser.accept(Transform.new(rules))
    end
  end
end

class Optimizer < Parslet::Optimizer
  rule((str(:x).absent? >> any).repeat(1)) do
    AbsentParser.new(x)
  end
end

parser = ErbParser.new
# optimized_parser = Optimizer.new.apply(parser)
# p optimized_parser.parse(File.read(ARGV.first))
p parser.parse_with_debug(File.read(ARGV.first))
