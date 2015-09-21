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

class MyCsvExpiredReport < Resque::Reports::CsvReport
  expire_in 3600
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


Person = Struct.new(:first_name, :second_name) do
  def full_name
    "#{first_name} #{second_name}"
  end
end

class ReportWithObjects < Resque::Reports::CsvReport
  source :select_data
  encoding UTF8

  directory File.join(Dir.tmpdir, 'resque-reports')

  table do
    column 'First name', :first_name
    column 'Second name', :second_name
    column 'Full name', :full_name
  end

  def select_data
    [Person.new('Steve', 'Jobs')]
  end
end

describe 'Resque::Reports::CsvReport successor' do
  describe '.csv_options' do
    context 'when custom options not set' do
      subject { MyCsvDefaultsReport.new }

      it 'sets csv_options defaults' do
        expect(subject.options).to eq MyCsvReport::DEFAULT_CSV_OPTIONS
      end
    end

    context 'when custom options are set' do
      subject { MyCsvReport.new('csv_options test') }

      let(:my_options) do
        MyCsvReport::DEFAULT_CSV_OPTIONS.merge(col_sep: ',', row_sep: "\n")
      end

      it 'merges csv_options with defaults' do
        expect(subject.options).to eq my_options
      end
    end
  end

  describe '#build' do
    context 'when report was built' do
      subject { MyCsvReport.new('was built test') }

      after { subject.build true }

      it { expect(subject).to be_exists }
      it do
        expect(File.read(subject.filename))
          .to eq <<-CSV.gsub(/^ {12}/, '')
            First one,Second,Third
            decorated: one,was built test - is second,3'rd row element is: 3
          CSV
      end
    end

    context 'when report source data contains decorated objects' do
      subject(:report) { ReportWithObjects.new }

      it 'builds report with decorated object attributes' do
        report.build(true)

        report_content = File.read(report.filename)

        expect(report_content).to include 'Steve;Jobs;Steve Jobs'
      end
    end
  end

  describe '#exists?' do
    context 'when report was built' do
      subject { MyCsvExpiredReport.new }

      before { subject.build }

      it do
        Timecop.travel(1.hour.since) do
          expect(subject.exists?).to be_falsey
        end
      end

      it do
        Timecop.travel(30.minutes.since) do
          expect(subject.exists?).to be_truthy
        end
      end
    end
  end
end
