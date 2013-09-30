# coding: utf-8
require 'spec_helper'
require 'resque/reports'

class Resque::Reports::MyCsvReport < Resque::Reports::CsvReport
  source :select_data
  encoding UTF8

  directory File.join(Dir.home, '.resque-reports')

  table do |element|
    column 'First', "#{element} - is first"
  end

  create do |param1, param2|
    @main_param = param1
    @secondary_param = param2
  end

  def select_data
    [:one, @main_param]
  end
end

describe Resque::Reports::ReportJob do
  let(:my_report) { Resque::Reports::MyCsvReport.new('.execute test','test') }
  let(:exec_params) { ['Resque::Reports::MyCsvReport', "[\".execute test\", \"test\",true]"] }

  describe '.execute' do
    before { Resque::Reports::MyCsvReport.stub(:new => my_report) }

    context 'when building report' do
      before { my_report.stub(:build => nil) }

      it { expect(Resque::Reports::MyCsvReport).to receive(:new).with('.execute test','test') }
      it { expect(my_report).to receive(:build).with(true) }

      after { Resque::Reports::ReportJob.execute(*exec_params) }

    end
    context 'when wrong class given' do
      it 'sends invalid class name' do
        expect { Resque::Reports::ReportJob.execute('MyWrongReport', "[true]") }.to raise_error(NameError)
      end

      it 'sends class that is not BaseReport successor' do
        expect { Resque::Reports::ReportJob.execute('Object', "[true]") }.to raise_error(RuntimeError)
      end
    end

    context 'when events are firing' do
      context 'when works default handlers' do
        context 'when error occurs' do
          before { my_report.stub(:build_table_row) { raise 'Custom error' } }

          it { expect { Resque::Reports::ReportJob.execute(*exec_params) }.to raise_error("Custom error") }
        end

        context 'when progress is changed' do
          before { described_class.stub(:at => nil) }

          it { described_class.should_receive(:at).with(2, 2, nil) }

          after { Resque::Reports::ReportJob.execute(*exec_params) }
        end
      end

      context 'when works custom handlers' do
        before do
          my_report.stub(:error_handling) { |e| raise "Boom! #{e.message}" }
        end

        context 'when error occurs' do
          before { my_report.stub(:build_table_row) { raise 'Custom error' } }

          it { expect { Resque::Reports::ReportJob.execute(*exec_params) }.to raise_error("Boom! Custom error") }
        end

        context 'when progress is changed' do
          before do
            described_class.stub(:at => nil)
            my_report.stub(:progress_message) { |p,t| "my progress: #{p} / #{t}" }
          end

          it { described_class.should_receive(:at).with(2, 2, 'my progress: 2 / 2') }

          after { Resque::Reports::ReportJob.execute(*exec_params) }
        end
      end
    end
  end
end
