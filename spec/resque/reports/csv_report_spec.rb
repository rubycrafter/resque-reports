# coding: utf-8
require 'spec_helper'
require 'stringio'

require 'resque/reports/csv_report'

class MyCsvReport < Resque::Reports::CsvReport
  source :select_data
  encoding UTF8

  csv_options col_sep: ','

  directory File.join(Dir.home, '.resque-reports')

  table do |element|
    column 'First one', :decorate_first
    column 'Second', "#{element} - is second"
  end

  create do |param|
    @main_param = param
  end

  def decorate_first(element)
    "decorated: #{element}"
  end

  def select_data
    [:one, @main_param]
  end
end

class MyCsvDefaultsReport < Resque::Reports::CsvReport
  source :select_data
  encoding UTF8

  directory File.join(Dir.home, '.resque-reports')

  table do |element|
    column 'Uno', "#{element} - is value"
  end

  def select_data
    [:one, @main_param]
  end
end

describe 'Resque::Reports::CsvReport successor' do
  describe '.csv_options' do
    context 'when custom options not set' do
      subject { MyCsvDefaultsReport.new }

      it 'sets csv_options defaults' do
        subject.options.should eq MyCsvReport::DEFAULT_CSV_OPTIONS
      end
    end

    context 'when custom options are set' do
      subject { MyCsvReport.new('csv_options test') }

      it 'merges csv_options with defaults' do
        subject.options.should eq MyCsvReport::DEFAULT_CSV_OPTIONS.merge(col_sep: ',')
      end
    end
  end

  describe '#build' do
    context 'when report was built' do
      subject { MyCsvReport.new('was built test') }

      before { subject.build true }

      its(:exists?) { should be_true }
      it { File.read(subject.filename).should eq "First one,Second\r\ndecorated: one,one - is second\r\ndecorated: was built test,was built test - is second\r\n" }
    end
  end
end
