# coding: utf-8
require 'spec_helper'
require 'stringio'

require 'resque/reports/csv_report'

class MyCsvReport < Resque::Reports::CsvReport
  queue :csv_reports
  source :select_data
  encoding UTF8

  csv_options col_sep: ',', row_sep: "\n"

  directory File.join(Dir.home, '.resque-reports')

  table do |element|
    column 'First one', decorate_first(element[:first])
    column 'Second', "#{element[:second]} - is second"
    column 'Third', :third, formatter: :cute_third
  end

  create do |param|
    @main_param = param
  end

  def cute_third_formatter(column_value)
    "3'rd row element is: #{column_value}"
  end

  def decorate_first(element)
    "decorated: #{element}"
  end

  def select_data
    [{:first => :one, :second => @main_param, :third => 3}]
  end
end

class MyCsvDefaultsReport < Resque::Reports::CsvReport
  source :select_data
  encoding UTF8

  directory File.join(Dir.tmpdir, 'resque-reports')

  table do |element|
    column 'Uno', "#{element} - is value"
  end

  def select_data
    []
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

      let(:my_options) do
        MyCsvReport::DEFAULT_CSV_OPTIONS.merge(col_sep: ',', row_sep: "\n")
      end

      it 'merges csv_options with defaults' do
        subject.options.should eq my_options
      end
    end
  end

  describe '#build' do
    context 'when report was built' do
      subject { MyCsvReport.new('was built test') }

      before { subject.build true }

      its(:exists?) { should be_true }
      it do
        File.read(subject.filename)
          .should eq <<-CSV.gsub(/^ {12}/, "")
            First one,Second,Third
            decorated: one,was built test - is second,3'rd row element is: 3
          CSV
      end
    end
  end
end
