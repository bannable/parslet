# frozen_string_literal: true

require 'case'
require 'text/highlight'

require 'document'
require 'example'

class ExampleRunner
  def run(args)
    Dir[File.join(args.last, '*.textile')].each do |name|
      puts name.white
      Document.new(name).process
    end
  end
end

ExampleRunner.new.run(ARGV) if $PROGRAM_NAME == __FILE__
