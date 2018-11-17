# frozen_string_literal: true

class NopClass
  def nop; end
end

nop = NopClass.new
fal = nil

n = 1_000_000
require 'benchmark'
Benchmark.bm(9) do |bm|
  bm.report(:unless)    { n.times { method_call if fal } }
  bm.report(:nop)       { n.times { nop.nop } }
end
