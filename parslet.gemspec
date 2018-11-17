# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'parslet'
  s.version = '2.0'

  s.authors = ['Kaspar Schiess', 'Joe Truba']
  s.email = 'joe@bannable.net'
  s.extra_rdoc_files = ['README']
  s.files = %w[HISTORY.txt LICENSE Rakefile README parslet.gemspec] + Dir.glob('{lib,spec,example}/**/*')
  s.homepage = 'http://bannable.github.io/parslet'
  s.license = 'MIT'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.summary = 'Parser construction library with great error reporting in Ruby.'
end
