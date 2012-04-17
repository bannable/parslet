# Base class for all parslets, handles orchestration of calls and implements
# a lot of the operator and chaining methods.
#
# Also see Parslet::Atoms::DSL chaining parslet atoms together.
#
class Parslet::Atoms::Base
  include Parslet::Atoms::Precedence
  include Parslet::Atoms::DSL
  include Parslet::Atoms::CanFlatten
  
  # Internally, all parsing functions return either an instance of Fail 
  # or an instance of Success. 
  #
  class Fail < Struct.new(:message)
    def error?; true end
  end

  # Internally, all parsing functions return either an instance of Fail 
  # or an instance of Success.
  #
  class Success < Struct.new(:result)
    def error?; false end
  end
  
  # Given a string or an IO object, this will attempt a parse of its contents
  # and return a result. If the parse fails, a Parslet::ParseFailed exception
  # will be thrown. 
  #
  def parse(io, prefix_parse=false)
    source = io.respond_to?(:line_and_column) ? 
      io : 
      Parslet::Source.new(io)
    
    context = Parslet::Atoms::Context.new
    
    result = nil
    value = apply(source, context)
    
    # If we didn't succeed the parse, raise an exception for the user. 
    # Stack trace will be off, but the error tree should explain the reason
    # it failed.
    if value.error?
      @last_cause = value.message
      @last_cause.raise
    end
    
    # assert: value is a success answer
    
    # If we haven't consumed the input, then the pattern doesn't match. Try
    # to provide a good error message (even asking down below)
    if !prefix_parse && !source.eof?
      # Do we know why we stopped matching input? If yes, that's a good
      # error to fail with. Otherwise just report that we cannot consume the
      # input.
      old_pos = source.pos
      @last_cause = source.error(
        "Don't know what to do with #{source.read(10).to_s.inspect}", old_pos)

      @last_cause.raise(Parslet::UnconsumedInput)
    end
    
    return flatten(value.result)
  end

  #---
  # Calls the #try method of this parslet. In case of a parse error, apply
  # leaves the source in the state it was before the attempt. 
  #+++
  def apply(source, context) # :nodoc:
    old_pos = source.pos
    
    result = context.cache(self, source) {
      try(source, context)
    }
    
    # This has just succeeded, so last_cause must be empty
    unless result.error?
      @last_cause = nil 
      return result
    end
    
    # We only reach this point if the parse has failed. Rewind the input.
    source.pos = old_pos
    return result # is instance of Fail
  end
  
  # Override this in your Atoms::Base subclasses to implement parsing
  # behaviour. 
  #
  def try(source, context)
    raise NotImplementedError, \
      "Atoms::Base doesn't have behaviour, please implement #try(source, context)."
  end


  # Debug printing - in Treetop syntax. 
  #
  def self.precedence(prec) # :nodoc:
    define_method(:precedence) { prec }
  end
  precedence BASE
  def to_s(outer_prec=OUTER) # :nodoc:
    if outer_prec < precedence
      "("+to_s_inner(precedence)+")"
    else
      to_s_inner(precedence)
    end
  end
  def inspect # :nodoc:
    to_s(OUTER)
  end
private

  # Produces an instance of Success and returns it. 
  #
  def success(result)
    Success.new(result)
  end

  # Produces an instance of Fail and returns it. 
  #
  def error(source, str, children=nil)
    cause = source.error(str)
    cause.children = children || []
    Fail.new(cause)
  end

  # Produces an instance of Fail and returns it. 
  #
  def error_at(source, str, pos, children=nil)
    cause = source.error(str, pos)
    cause.children = children || []
    Fail.new(cause)
  end
end
