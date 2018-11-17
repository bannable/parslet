# frozen_string_literal: true

def pair
  [true, '123']
end

Success = Struct.new(:value)
def struct
  Success.new('123')
end

class SuccessO
  def initialize(value)
    @value = value
  end
end
def klass
  SuccessO.new('123')
end

def raise_ex
  raise '123'
end

n = 100_000
require 'benchmark'
Benchmark.bm(9) do |bm|
  bm.report(:pair)    { n.times { pair } }
  bm.report(:struct)  { n.times { struct } }
  bm.report(:klass)  { n.times { klass } }
  bm.report(:throw)  do
    n.times do
      raise_ex
    rescue StandardError
      nil
    end
  end
end
