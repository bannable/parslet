# frozen_string_literal: true

module Parslet
  module Atoms
    # Matches a parslet repeatedly.
    #
    # Example:
    #
    #   str('a').repeat(1,3)  # matches 'a' at least once, but at most three times
    #   str('a').maybe        # matches 'a' if it is present in the input (repeat(0,1))
    #
    class Repetition < Parslet::Atoms::Base
      attr_reader :min, :max, :parslet
      def initialize(parslet, min, max, tag = :repetition)
        super()

        if max == 0
          raise ArgumentError,
                "Asking for zero repetitions of a parslet. (#{parslet.inspect} repeating #{min},#{max})"
        end

        @parslet = parslet
        @min = min
        @max = max
        @tag = tag
      end

      def error_msgs
        @error_msgs ||= {
          minrep: "Expected at least #{min} of #{parslet.inspect}",
          unconsumed: 'Extra input after last repetition'
        }
      end

      def try(source, context, consume_all)
        occ = 0
        accum = [@tag] # initialize the result array with the tag (for flattening)
        start_pos = source.pos

        break_on = nil
        loop do
          success, value = parslet.apply(source, context, false)

          break_on = value
          break unless success

          occ += 1
          accum << value

          # If we're not greedy (max is defined), check if that has been reached.
          return succ(accum) if max && occ >= max
        end

        # Last attempt to match parslet was a failure, failure reason in break_on.

        # Greedy matcher has produced a failure. Check if occ (which will
        # contain the number of successes) is >= min.
        if occ < min
          return context.err_at(
            self,
            source,
            error_msgs[:minrep],
            start_pos,
            [break_on]
          )
        end

        # consume_all is true, that means that we're inside the part of the parser
        # that should consume the input completely. Repetition failing here means
        # probably that we didn't.
        #
        # We have a special clause to create an error here because otherwise
        # break_on would get thrown away. It turns out, that contains very
        # interesting information in a lot of cases.
        #
        if consume_all && source.chars_left > 0
          return context.err(
            self,
            source,
            error_msgs[:unconsumed],
            [break_on]
          )
        end

        succ(accum)
      end

      precedence REPETITION
      def to_s_inner(prec)
        minmax = "{#{min}, #{max}}"
        minmax = '?' if min == 0 && max == 1

        parslet.to_s(prec) + minmax
      end
    end
  end
end
