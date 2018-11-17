# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Source do
  describe 'using simple input' do
    let(:str)     { 'a' * 100 + "\n" + 'a' * 100 + "\n" }
    let(:source)  { described_class.new(str) }

    describe '<- #read(n)' do
      it 'should not raise error when the return value is nil' do
        described_class.new('').consume(1)
      end
      it "should return 100 'a's when reading 100 chars" do
        expect(source.consume(100)).to eq('a' * 100)
      end
    end
    describe '<- #chars_left' do
      subject { source.chars_left }

      it { is_expected.to eq(202) }
      context 'after depleting the source' do
        before(:each) { source.consume(10_000) }

        it { is_expected.to eq(0) }
      end
    end
    describe '<- #pos' do
      subject { source.pos.charpos }

      it { is_expected.to eq(0) }
      context 'after reading a few bytes' do
        it 'should still be correct' do
          pos = 0
          10.times do
            pos += (n = rand(1..10))
            source.consume(n)

            expect(source.pos.charpos).to eq(pos)
          end
        end
      end
    end
    describe '<- #pos=(n)' do
      subject { source.pos.charpos }
      10.times do
        pos = rand(200)
        context "setting position #{pos}" do
          before(:each) { source.bytepos = pos }

          it { is_expected.to eq(pos) }
        end
      end
    end
    describe '#chars_until' do
      it 'should return 100 chars before line end' do
        expect(source.chars_until("\n")).to eq(100)
      end
    end
    describe '<- #column & #line' do
      subject { source.line_and_column }

      it { is_expected.to eq([1, 1]) }

      context 'on the first line' do
        it 'should increase column with every read' do
          10.times do |i|
            expect(source.line_and_column.last).to eq(1 + i)
            source.consume(1)
          end
        end
      end
      context 'on the second line' do
        before(:each) { source.consume(101) }
        it { is_expected.to eq([2, 1]) }
      end
      context 'after reading everything' do
        before(:each) { source.consume(10_000) }

        context 'when seeking to 9' do
          before(:each) { source.bytepos = 9 }
          it { is_expected.to eq([1, 10]) }
        end
        context 'when seeking to 100' do
          before(:each) { source.bytepos = 100 }
          it { is_expected.to eq([1, 101]) }
        end
        context 'when seeking to 101' do
          before(:each) { source.bytepos = 101 }
          it { is_expected.to eq([2, 1]) }
        end
        context 'when seeking to 102' do
          before(:each) { source.bytepos = 102 }
          it { is_expected.to eq([2, 2]) }
        end
        context 'when seeking beyond eof' do
          it 'should not throw an error' do
            source.bytepos = 1000
          end
        end
      end
      context 'reading char by char, storing the results' do
        attr_reader :results
        before(:each) do
          @results = {}
          while source.chars_left > 0
            pos = source.pos.charpos
            @results[pos] = source.line_and_column
            source.consume(1)
          end

          expect(@results.entries.size).to eq(202)
          @results
        end

        context 'when using pos argument' do
          it 'should return the same results' do
            results.each do |pos, result|
              expect(source.line_and_column(pos)).to eq(result)
            end
          end
        end
        it 'should give the same results when seeking' do
          results.each do |pos, result|
            source.bytepos = pos
            expect(source.line_and_column).to eq(result)
          end
        end
        it 'should give the same results when reading' do
          cur = source.bytepos = 0
          while source.chars_left > 0
            expect(source.line_and_column).to eq(results[cur])
            cur += 1
            source.consume(1)
          end
        end
      end
    end
  end

  describe 'reading encoded input' do
    let(:source) { described_class.new('éö変わる') }

    def r(str)
      Regexp.new(Regexp.escape(str))
    end

    it 'should read characters, not bytes' do
      expect(source).to match(r('é'))
      source.consume(1)
      expect(source.pos.charpos).to eq(1)
      expect(source.bytepos).to eq(2)

      expect(source).to match(r('ö'))
      source.consume(1)
      expect(source.pos.charpos).to eq(2)
      expect(source.bytepos).to eq(4)

      expect(source).to match(r('変'))
      source.consume(1)

      source.consume(2)
      expect(source.chars_left).to eq(0)
      expect(source.chars_left).to eq(0)
    end
  end
end
