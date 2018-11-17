# frozen_string_literal: true

module Parslet
  module Atoms
    # Evaluates a block at parse time. The result from the block must be a parser
    # (something which implements #apply). In the first case, the parser will then
    # be applied to the input, creating the result.
    #
    # Dynamic parses are never cached.
    #
    # Example:
    #   dynamic { rand < 0.5 ? str('a') : str('b') }
    #
    class Dynamic < Parslet::Atoms::Base
      attr_reader :block

      def initialize(block)
        @block = block
      end

      def cached?
        false
      end

      def try(source, context, consume_all)
        result = block.call(source, context)

        # Result is a parslet atom.
        result.apply(source, context, consume_all)
      end

      def to_s_inner(_prec)
        'dynamic { ... }'
      end
    end
  end
end
