# frozen_string_literal: true

module Parslet
  class Expression
    class Treetop
      class Parser < Parslet::Parser
        root(:expression)

        rule(:expression) { alternatives }

        # alternative 'a' / 'b'
        rule(:alternatives) do
          (simple >> (spaced('/') >> simple).repeat).as(:alt)
        end

        # sequence by simple concatenation 'a' 'b'
        rule(:simple) { occurrence.repeat(1).as(:seq) }

        # occurrence modifiers
        rule(:occurrence) do
          atom.as(:repetition) >> spaced('*').as(:sign) |
            atom.as(:repetition) >> spaced('+').as(:sign) |
            atom.as(:repetition) >> repetition_spec |
            atom.as(:maybe) >> spaced('?') |
            atom
        end

        rule(:atom) do
          spaced('(') >> expression.as(:unwrap) >> spaced(')') |
            dot |
            string |
            char_class
        end

        # a character class
        rule(:char_class) do
          (str('[') >>
            (str('\\') >> any |
            str(']').absent? >> any).repeat(1) >>
          str(']')).as(:match) >> space?
        end

        # anything at all
        rule(:dot) { spaced('.').as(:any) }

        # recognizing strings
        rule(:string) do
          str('\'') >>
            (
              (str('\\') >> any) |
              (str("'").absent? >> any)
            ).repeat.as(:string) >>
            str('\'') >> space?
        end

        # repetition specification like {1, 2}
        rule(:repetition_spec) do
          spaced('{') >>
            integer.maybe.as(:min) >> spaced(',') >>
            integer.maybe.as(:max) >> spaced('}')
        end
        rule(:integer) do
          match['0-9'].repeat(1)
        end

        # whitespace handling
        rule(:space) { match("\s").repeat(1) }
        rule(:space?) { space.maybe }

        def spaced(str)
          str(str) >> space?
        end
      end

      class Transform < Parslet::Transform
        rule(repetition: simple(:rep), sign: simple(:sign)) do
          min = sign == '+' ? 1 : 0
          Parslet::Atoms::Repetition.new(rep, min, nil)
        end
        rule(repetition: simple(:rep), min: simple(:min), max: simple(:max)) do
          Parslet::Atoms::Repetition.new(rep,
                                         Integer(min || 0),
                                         max && Integer(max) || nil)
        end

        rule(alt: subtree(:alt))       { Parslet::Atoms::Alternative.new(*alt) }
        rule(seq: sequence(:s))        { Parslet::Atoms::Sequence.new(*s) }
        rule(unwrap: simple(:u))       { u }
        rule(maybe: simple(:m))        { |d| d[:m].maybe }
        rule(string: simple(:s))       { Parslet::Atoms::Str.new(s) }
        rule(match: simple(:m))        { Parslet::Atoms::Re.new(m) }
        rule(any: simple(:a))          { Parslet::Atoms::Re.new('.') }
      end
    end
  end
end
