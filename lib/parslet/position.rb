# frozen_string_literal: true

module Parslet
  # Encapsules the concept of a position inside a string.
  class Position
    attr_reader :bytepos

    include Comparable

    def initialize(string, bytepos)
      @string = string
      @bytepos = bytepos
    end

    def charpos
      @string.byteslice(0, @bytepos).size
    end

    def <=>(b)
      bytepos <=> b.bytepos
    end
  end
end
