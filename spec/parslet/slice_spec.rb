# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Slice do
  def cslice(string, offset, cache = nil)
    described_class.new(
      Parslet::Position.new(string, offset),
      string, cache
    )
  end

  describe 'construction' do
    it 'should construct from an offset and a string' do
      cslice('foobar', 40)
    end
  end
  context "('foobar', 40, 'foobar')" do
    let(:slice) { cslice('foobar', 40) }
    describe 'comparison' do
      it 'should be equal to other slices with the same attributes' do
        other = cslice('foobar', 40)
        expect(slice).to eq(other)
        expect(other).to eq(slice)
      end
      it 'should be equal to other slices (offset is irrelevant for comparison)' do
        other = cslice('foobar', 41)
        expect(slice).to eq(other)
        expect(other).to eq(slice)
      end
      it 'should be equal to a string with the same content' do
        expect(slice).to eq('foobar')
      end
      it 'should be equal to a string (inversed operands)' do
        expect('foobar').to eq(slice)
      end
      it 'should not be equal to a string' do
        expect(slice).not_to equal('foobar')
      end
      it 'should not be eql to a string' do
        expect(slice).not_to eql('foobar')
      end
      it 'should not hash to the same number' do
        expect(slice.hash).not_to eq('foobar'.hash)
      end
    end
    describe 'offset' do
      it 'should return the associated offset' do
        expect(slice.offset).to eq(6)
      end
      it 'should fail to return a line and column' do
        expect { slice.line_and_column }.to raise_error(ArgumentError)
      end

      context 'when constructed with a source' do
        let(:slice) do
          cslice(
            'foobar', 40,
            flexmock(:cache, line_and_column: [13, 14])
          )
        end
        it 'should return proper line and column' do
          expect(slice.line_and_column).to eq([13, 14])
        end
      end
    end
    describe 'string methods' do
      describe 'matching' do
        it 'should match as a string would' do
          expect(slice).to match(/bar/)
          expect(slice).to match(/foo/)

          md = slice.match(/f(o)o/)
          expect(md.captures.first).to eq('o')
        end
      end

      describe '<- #size' do
        subject { slice.size }
        it { is_expected.to eq(6) }
      end

      describe '<- #length' do
        subject { slice.length }
        it { is_expected.to eq(6) }
      end

      describe '<- #+' do
        let(:other) { cslice('baz', 10) }
        subject { slice + other }

        it 'should concat like string does' do
          expect(subject.size).to eq(9)
          expect(subject).to eq('foobarbaz')
          expect(subject.offset).to eq(6)
        end
      end
    end

    describe 'conversion' do
      describe '<- #to_slice' do
        it 'should return self' do
          expect(slice.to_slice).to eq(slice)
        end
      end

      describe '<- #to_sym' do
        it 'should return :foobar' do
          expect(slice.to_sym).to eq(:foobar)
        end
      end

      describe 'cast to Float' do
        it 'should return a float' do
          expect(Float(cslice('1.345', 11))).to eq(1.345)
        end
      end

      describe 'cast to Integer' do
        it 'should cast to integer as a string would' do
          s = cslice('1234', 40)
          expect(Integer(s)).to eq(1234)
          expect(s.to_i).to eq(1234)
        end

        it 'should fail when Integer would fail on a string' do
          # In 2.6, Integer was changed to take an :exception parameter which
          # defines the failure behavior. The new default behavior is to return
          # nil instead of raising an exception, unless to_i is defined, in which
          # case it will fall back to calling that first.
          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0-preview3')
            expect(Integer(slice)).to eq(0)
          else
            expect { Integer(slice) }.to raise_error(ArgumentError, /invalid value/)
          end
        end

        it 'should turn into zero when a string would' do
          expect(slice.to_i).to eq(0)
        end
      end
    end

    describe 'inspection and string conversion' do
      describe '#inspect' do
        subject { slice.inspect }
        it { is_expected.to eq('"foobar"@6') }
      end
      describe '#to_s' do
        subject { slice.to_s }
        it { is_expected.to eq('foobar') }
      end
    end
    describe 'serializability' do
      it 'should serialize' do
        Marshal.dump(slice)
      end
      context 'when storing a line cache' do
        let(:slice) { cslice('foobar', 40, Parslet::Source::LineCache.new) }
        it 'should serialize' do
          Marshal.dump(slice)
        end
      end
    end
  end
end
