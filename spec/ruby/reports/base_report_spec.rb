# coding: utf-8
require 'spec_helper'
require 'stringio'

class MyTypeReport < Ruby::Reports::BaseReport
  def initialize(*args)
    config.extension = :type
    super
  end

  def write(io, force = false)
    write_line io, table.build_header

    iterator.data_each(true) do |element|
      write_line io, table.build_row(element)
    end
  end

  def write_line(io, row)
    io << "#{row.nil? ? 'nil' : row.join('|')}\r\n"
  end
end

class MyReport < MyTypeReport
  config(
    queue: :my_type_reports,
    source: :select_data,
    encoding: 'utf-8',
    directory: File.join(Dir.tmpdir, 'resque-reports')
  )

  table do |element|
    column 'First one', :one
    column 'Second', :two, formatter: :decorate_second
  end

  attr_reader :main_param

  def initialize(param)
    super
    @main_param = param
  end

  def self.decorate_second(text)
    "#{text} - is second"
  end

  def formatter
    self.class
  end

  def query
    @query ||= Query.new(self)
  end

  class Query
    pattr_initialize :report
    def select_data
      [{one: 'one', two: 'one'}, {one: report.main_param, two: report.main_param}]
    end
  end
end

describe 'Resque::Reports::BaseReport successor' do
  let(:io) { StringIO.new }
  let(:my_report) { MyReport.new('test') }
  let(:dummy) { Hash.new }

  describe '#bg_build' do
    let(:job_class) { Resque::Reports::ReportJob }

    context 'when report is building twice' do
      subject { MyReport.new('#bg_build test') }

      before { allow(job_class).to receive(:enqueue_to).and_return('job_id') }

      it do
        expect(job_class).to receive(:enqueue_to).twice
      end

      after do
        2.times { subject.bg_build true }
      end
    end

    context 'when report is building' do
      subject { MyReport.new('#bg_build test') }

      before { allow(job_class).to receive(:enqueue_to).and_return('job_id') }

      it { expect(job_class).to receive(:enqueue_to) }

      after { subject.bg_build true }
    end

    context 'when report is not build yet' do
      subject { MyReport.new('#bg_build test') }

      before do
        allow(job_class).to receive(:enqueued?).and_return(double('Meta', meta_id: 'enqueued_job_id'))
      end

      it { expect(subject.bg_build(true)).to eq 'enqueued_job_id' }
    end
  end
end
