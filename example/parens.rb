# frozen_string_literal: true

# A small example that demonstrates the power of tree pattern matching. Also
# uses '.as(:name)' to construct a tree that can reliably be matched
# afterwards.

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'pp'
require 'parslet'

module LISP
  class Parser < Parslet::Parser
    rule(:balanced) do
      str('(').as(:l) >> balanced.maybe.as(:m) >> str(')').as(:r)
    end

    root(:balanced)
  end

  class Transform < Parslet::Transform
    rule(l: '(', m: simple(:x), r: ')') do
      # innermost :m will contain nil
      x.nil? ? 1 : x + 1
    end
  end
end

parser = LISP::Parser.new
transform = LISP::Transform.new
%w[
  ()
  (())
  ((((()))))
  ((())
].each do |pexp|
  begin
    result = parser.parse(pexp)
    puts "#{format('%20s', pexp)}: #{result.inspect} (#{transform.apply(result)} parens)"
  rescue Parslet::ParseFailed => m
    puts "#{format('%20s', pexp)}: #{m}"
  end
  puts
end
