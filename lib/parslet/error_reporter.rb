# frozen_string_literal: true

# A namespace for all error reporters.
#
module Parslet
  module ErrorReporter; end
end

require 'parslet/error_reporter/tree'
require 'parslet/error_reporter/deepest'
require 'parslet/error_reporter/contextual'
