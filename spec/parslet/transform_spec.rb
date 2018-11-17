# frozen_string_literal: true

require 'spec_helper'

require 'parslet'

describe Parslet::Transform do
  include Parslet

  let(:transform) { Parslet::Transform.new }

  class A < Struct.new(:elt); end
  class B < Struct.new(:elt); end
  class C < Struct.new(:elt); end
  class Bi < Struct.new(:a, :b); end

  describe 'delayed construction' do
    context 'given simple(:x) => A.new(x)' do
      before(:each) do
        transform.rule(simple(:x)) { |d| A.new(d[:x]) }
      end

      it "should transform 'a' into A.new('a')" do
        expect(transform.apply('a')).to eq(A.new('a'))
      end
      it "should transform ['a', 'b'] into [A.new('a'), A.new('b')]" do
        expect(transform.apply(%w[a b])).to eq(
          [A.new('a'), A.new('b')]
        )
      end
    end
    context 'given rules on {:a => simple(:x)} and {:b => :_x}' do
      before(:each) do
        transform.rule(a: simple(:x)) { |d| A.new(d[:x]) }
        transform.rule(b: simple(:x)) { |d| B.new(d[:x]) }
      end

      it "should transform {:d=>{:b=>'c'}} into d => B('c')" do
        expect(transform.apply(d: { b: 'c' })).to eq({ d: B.new('c') })
      end
      it "should transform {:a=>{:b=>'c'}} into A(B('c'))" do
        expect(transform.apply(a: { b: 'c' })).to eq(A.new(B.new('c')))
      end
    end
    describe 'pulling out subbranches' do
      before(:each) do
        transform.rule(a: { b: simple(:x) }, d: { e: simple(:y) }) do |d|
          Bi.new(*d.values_at(:x, :y))
        end
      end

      it "should yield Bi.new('c', 'f')" do
        expect(transform.apply(a: { b: 'c' }, d: { e: 'f' })).to eq(
          Bi.new('c', 'f')
        )
      end
    end
  end
  describe 'dsl construction' do
    let(:transform) do
      Parslet::Transform.new do
        rule(simple(:x)) { A.new(x) }
      end
    end

    it 'should still evaluate rules correctly' do
      expect(transform.apply('a')).to eq(A.new('a'))
    end
  end
  describe 'class construction' do
    class OptimusPrime < Parslet::Transform
      rule(a: simple(:x)) { A.new(x) }
      rule(b: simple(:x)) { B.new(x) }
    end
    let(:transform) { OptimusPrime.new }

    it 'should evaluate rules' do
      expect(transform.apply(a: 'a')).to eq(A.new('a'))
    end

    context 'optionally raise when no match found' do
      class BumbleBee < Parslet::Transform
        def initialize(&block)
          super(raise_on_unmatch: true, &block)
        end
        rule(a: simple(:x)) { A.new(x) }
      end
      let(:transform) { BumbleBee.new }

      it 'should evaluate rules' do
        expect(transform.apply(a: 'a')).to eq(A.new('a'))
      end

      it 'should raise when no rules are matched' do
        expect {
          transform.apply(z: 'z')
        }.to raise_error(NotImplementedError, /Failed to match/)
      end
    end

    context 'with inheritance' do
      class OptimusPrimeJunior < OptimusPrime
        rule(b: simple(:x)) { B.new(x.upcase) }
        rule(c: simple(:x)) { C.new(x) }
      end
      let(:transform) { OptimusPrimeJunior.new }

      it 'should inherit rules from its parent' do
        expect(transform.apply(a: 'a')).to eq(A.new('a'))
      end

      it 'should be able to override rules from its parent' do
        expect(transform.apply(b: 'b')).to eq(B.new('B'))
      end

      it 'should be able to define new rules' do
        expect(transform.apply(c: 'c')).to eq(C.new('c'))
      end
    end
  end
  describe '<- #call_on_match' do
    let(:bindings) { { foo: 'test' } }
    context 'when given a block of arity 1' do
      it 'should call the block' do
        called = false
        transform.call_on_match(bindings, lambda do |_dict|
          called = true
        end)

        expect(called).to eq(true)
      end
      it 'should yield the bindings' do
        transform.call_on_match(bindings, lambda do |dict|
          expect(dict).to eq(bindings)
        end)
      end
      it 'should execute in the current context' do
        foo = 'test'
        transform.call_on_match(bindings, lambda do |_dict|
          expect(foo).to eq('test')
        end)
      end
    end
    context 'when given a block of arity 0' do
      it 'should call the block' do
        called = false
        transform.call_on_match(bindings, proc do
          called = true
        end)

        expect(called).to eq(true)
      end
      it 'should have bindings as local variables' do
        expect(transform.call_on_match(bindings, proc { foo })).to eq('test')
      end
      it 'should execute in its own context' do
        @bar = 'test'
        transform.call_on_match(bindings, proc do
          if instance_variable_defined?('@bar')
            expect(instance_variable_get('@bar')).not_to eq('test')
          end
        end)
      end
    end
  end

  context 'various transformations (regression)' do
    context 'hashes' do
      it 'are matched completely' do
        transform.rule(a: simple(:x)) { raise }
        transform.apply(a: 'a', b: 'b')
      end
    end
  end

  context 'when not using the bindings as hash, but as local variables' do
    it 'should access the variables' do
      transform.rule(simple(:x)) { A.new(x) }
      expect(transform.apply('a')).to eq(A.new('a'))
    end
    it 'should allow context as local variable' do
      transform.rule(simple(:x)) { foo }
      expect(transform.apply('a', foo: 'bar')).to eq('bar')
    end
  end
end
