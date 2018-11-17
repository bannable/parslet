# frozen_string_literal: true

require 'tempfile'
require 'cod'

require 'site'
require 'fail_site'

class Example
  def initialize(title, file, line)
    @title = title
    @file = file
    @line = line

    @lines = []

    @sites = {}
    @site_by_line = {}
  end

  def to_s
    "'#{@title}'"
  end

  def <<(line)
    @lines << line
  end

  attr_reader :output

  def skip?
    !@lines.grep(/# =>/)
  end

  def run
    # Create a tempfile per output
    tempfiles = %i[err out].each_with_object({}) do |name, h|
      h[name] = Tempfile.new(name.to_s)
    end

    # Where code results are communicated.
    $instrumentation = Cod.pipe

    code = produce_example_code
    pid = fork do
      redirect_streams(tempfiles)
      # puts example_code
      eval(code, nil, @file, @line - 2)
    end
    Process.wait(pid)

    # Read these tempfiles.
    @output = tempfiles.each_with_object({}) do |(name, io), h|
      io.rewind
      h[name] = io.read
      io.close
    end

    loop do
      begin
        site_id, probe_value = $instrumentation.get
      rescue Exception => ex
        break if ex.message =~ /All pipe ends/
      end
      raise "No such site #{site_id}." unless @sites.key?(site_id)

      @sites[site_id].store probe_value
    end

    $instrumentation.close
    $instrumentation = nil

    $CHILD_STATUS.success?
  end

  def redirect_streams(io_hash)
    {
      out: $stdout,
      err: $stderr
    }.each do |name, io|
      io.reopen(io_hash[name])
    end
  end

  def produce_example_code
    root = __dir__

    '' \
      "$:.unshift #{root.inspect}\n" \
      "load 'prelude.rb'\n" <<
      instrument(@lines).join("\n") <<
      "\nload 'postscriptum.rb'\n"
  end

  def instrument(code)
    code.map do |line|
      md = line.match(/(?<pre>.*)# (?<type>=>|raises) (?<expectation>.*)/)
      next line unless md

      site = if md[:type] == 'raises'
               FailSite.new(line, md[:pre], md[:expectation].strip)
             else
               Site.new(line, md[:pre], md[:expectation].strip)
             end

      add_site site
      site.to_instrumented_line
    end
  end

  def add_site(site)
    @sites[site.id] = site
    @site_by_line[site.original_line] = site
  end

  def produce_modified_code
    @lines.map do |line|
      site = @site_by_line[line]
      next line unless site

      site.format_documentation_line
    end
  end

  def check_expectations
    @sites.each do |_, site|
      site.check
    end
  end
end
