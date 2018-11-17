# frozen_string_literal: true

require 'spec_helper'

describe Parslet::Source::RangeSearch do
  describe '<- #lbound' do
    context 'for a simple array' do
      let(:ary) { [10, 20, 30, 40, 50] }
      before(:each) { ary.extend Parslet::Source::RangeSearch }

      it 'should return correct answers for numbers not in the array' do
        expect(ary.lbound(5)).to eq(0)
        expect(ary.lbound(15)).to eq(1)
        expect(ary.lbound(25)).to eq(2)
        expect(ary.lbound(35)).to eq(3)
        expect(ary.lbound(45)).to eq(4)
      end
      it 'should return correct answers for numbers in the array' do
        expect(ary.lbound(10)).to eq(1)
        expect(ary.lbound(20)).to eq(2)
        expect(ary.lbound(30)).to eq(3)
        expect(ary.lbound(40)).to eq(4)
      end
      it 'should cover right edge case' do
        expect(ary.lbound(50)).to be_nil
        expect(ary.lbound(51)).to be_nil
      end
      it 'should cover left edge case' do
        expect(ary.lbound(0)).to eq(0)
      end
    end
    context 'for an empty array' do
      let(:ary) { [] }
      before(:each) { ary.extend Parslet::Source::RangeSearch }

      it 'should return nil' do
        expect(ary.lbound(1)).to be_nil
      end
    end
  end
end

describe Parslet::Source::LineCache do
  describe '<- scan_for_line_endings' do
    context 'calculating the line_and_columns' do
      let(:str) { "foo\nbar\nbazd" }

      it 'should return the first line if we have no line ends' do
        subject.scan_for_line_endings(0, nil)
        expect(subject.line_and_column(3)).to eq([1, 4])

        subject.scan_for_line_endings(0, '')
        expect(subject.line_and_column(5)).to eq([1, 6])
      end

      it 'should find the right line starting from pos 0' do
        subject.scan_for_line_endings(0, str)
        expect(subject.line_and_column(5)).to eq([2, 2])
        expect(subject.line_and_column(9)).to eq([3, 2])
      end

      it 'should find the right line starting from pos 5' do
        subject.scan_for_line_endings(5, str)
        expect(subject.line_and_column(11)).to eq([2, 3])
      end

      it 'should find the right line if scannning the string multiple times' do
        subject.scan_for_line_endings(0, str)
        subject.scan_for_line_endings(0, "#{str}\nthe quick\nbrown fox")
        expect(subject.line_and_column(10)).to eq([3, 3])
        expect(subject.line_and_column(24)).to eq([5, 2])
      end
    end
  end
end
