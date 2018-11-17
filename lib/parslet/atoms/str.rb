# frozen_string_literal: true

module Parslet
  module Atoms
    # Matches a string of characters.
    #
    # Example:
    #
    #   str('foo') # matches 'foo'
    #
    class Str < Parslet::Atoms::Base
      attr_reader :str
      def initialize(str)
        super()

        @str = str.to_s
        @pat = Regexp.new(Regexp.escape(str))
        @len = str.size
      end

      def error_msgs
        @error_msgs ||= {
          premature: 'Premature end of input',
          failed: "Expected #{str.inspect}, but got "
        }
      end

      def try(source, context, _consume_all)
        return succ(source.consume(@len)) if source.matches?(@pat)

        # Input ending early:
        return context.err(self, source, error_msgs[:premature]) \
          if source.chars_left < @len

        # Expected something, but got something else instead:
        error_pos = source.pos
        context.err_at(
          self, source,
          [error_msgs[:failed], source.consume(@len)], error_pos
        )
      end

      def to_s_inner(_prec)
        "'#{str}'"
      end
    end
  end
end
