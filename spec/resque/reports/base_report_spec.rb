# coding: utf-8
require 'spec_helper'
require 'stringio'

require 'resque-reports'

class MyTypeReport < Resque::Reports::BaseReport
  extension :type

  def write(io, force = false)
    write_line io, build_table_header

    data_each(true) do |element|
      write_line io, build_table_row(element)
    end
  end

  def write_line(io, row)
    io << "#{row.nil? ? 'nil' : row.join('|')}\r\n"
  end
end

class MyReport < MyTypeReport
  queue :my_type_reports
  source :select_data
  encoding UTF8

  directory File.join(Dir.tmpdir, 'resque-reports')

  table do |element|
    column 'First one', :one
    column 'Second', decorate_second(element[:two])
  end

  create do |param|
    @main_param = param
  end

  def decorate_second(text)
    "#{text} - is second"
  end

  def select_data
    [{one: 'one', two: 'one'}, {one: @main_param, two: @main_param}]
  end
end

describe 'Resque::Reports::BaseReport successor' do
  let(:io) { StringIO.new }
  let(:my_report) { MyReport.new('test') }
  let(:dummy) { Resque::Reports::Extensions::Dummy.new }

  describe '#extension' do
    before { File.stub(:exists? => true) }

    it { File.extname(my_report.filename).should eq '.type' }
  end

  describe '#source' do
    before { my_report.stub(select_data: [dummy]) }

    it { my_report.should_receive(:select_data) }

    after { my_report.build true }
  end

  describe '#directory' do
    subject { my_report.instance_variable_get(:@cache_file) }
    let(:tmpdir) { File.join(Dir.tmpdir, 'resque-reports') }

    it { subject.instance_variable_get(:@dir).should eq tmpdir }
  end

  describe '#create' do
    it { my_report.instance_variable_get(:@main_param).should eq 'test' }
  end

  describe '#encoding' do
    subject { my_report.instance_variable_get(:@cache_file) }
    let(:utf_coding) { Resque::Reports::Extensions::Encodings::UTF8 }

    it { subject.instance_variable_get(:@coding).should eq utf_coding }
  end

  describe '#write' do
    subject { MyReport.new('#write test') }

    before do
      subject.stub(:data_each) { |&block| block.call(dummy) }
      subject.stub(build_table_row: ['row'])
      subject.stub(build_table_header: ['header'])

      subject.write(io)
    end

    it { io.string.should eq "header\r\nrow\r\n" }
  end

  describe '#bg_build' do
    let(:job_class) { Resque::Reports::ReportJob }

    context 'when report is building twice' do
      subject { MyReport.new('#bg_build test') }

      before { job_class.stub(enqueue_to: 'job_id') }

      it do
        job_class
          .should_receive(:enqueue_to).twice
          #.with(:my_type_reports, 'MyReport', '["#bg_build test",true]')

      end

      after do
        2.times { subject.bg_build true }
      end
    end

    context 'when report is building' do
      subject { MyReport.new('#bg_build test') }

      before { job_class.stub(enqueue_to: 'job_id') }

      it do
        job_class
          .should_receive(:enqueue_to)
          #.with(:my_type_reports, 'MyReport', '["#bg_build test",true]')
      end

      after  { subject.bg_build true }
    end

    context 'when report is not build yet' do
      subject { MyReport.new('#bg_build test') }

      before do
        job_class.stub(enqueued?: double('Meta', meta_id: 'enqueued_job_id'))
      end

      it { subject.bg_build(true).should eq 'enqueued_job_id' }
    end
  end

  describe '#build' do
    subject { MyReport.new('#build test') }

    it { subject.should_receive(:decorate_second).exactly(3).times }

    after  { subject.build true }

    context 'when report was built' do
      subject { MyReport.new('was built test') }

      before { subject.build true }

      its(:exists?) { should be_true }
      it do
        File.read(subject.filename)
          .should eq <<-REPORT.gsub(/^ {12}/, '')
            First one|Second\r
            one|one - is second\r
            was built test|was built test - is second\r
          REPORT
      end
    end
  end

  describe '#data_each' do
    subject { MyReport.new('#data_each test') }

    it { subject.should_receive(:data_each) }

    after { subject.write(io) }
  end

  describe '#build_table_header' do
    subject { MyReport.new('#build_table_header test') }

    it { subject.should_receive(:build_table_header) }

    after { subject.write(io) }
  end

  describe '#build_table_row' do
    subject { MyReport.new('#build_table_row test') }

    it { subject.should_receive(:build_table_row).twice }

    after { subject.write(io) }
  end

end
