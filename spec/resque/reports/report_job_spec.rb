# coding: utf-8
require 'spec_helper'
require 'resque-reports'

module Reports
  class MyCsvReport < Resque::Reports::CsvReport
    config(
      queue: :csv_reports,
      source: :select_data,
      encoding: 'utf-8',
      directory: File.join(Dir.home, '.resque-reports')
    )

    table do |element|
      column 'First', "#{element} - is first"
    end

    attr_reader :main_param
    def initialize(param1, param2)
      super
      @main_param = param1
      @secondary_param = param2
    end

    def query
      @query ||= Query.new(self)
    end

    class Query
      pattr_initialize :report
      def select_data
        [:one, report.main_param]
      end
    end
  end
end

describe Resque::Reports::ReportJob do
  let(:my_report) { Reports::MyCsvReport.new('.execute test', 'test') }
  let!(:my_report_table) { my_report.send(:table) }
  let(:exec_params) do
    ['Reports::MyCsvReport', '[".execute test", "test",true]']
  end

  describe '.execute' do
    before { allow(Reports::MyCsvReport).to receive(:new).and_return(my_report) }

    context 'when building report' do
      before { allow(my_report).to receive(:build).and_return(nil) }

      it do
        expect(Reports::MyCsvReport)
          .to receive(:new).with('.execute test', 'test')
      end
      it { expect(my_report).to receive(:build).with(true) }

      after { described_class.execute(*exec_params) }

    end
    context 'when wrong class given' do
      it 'sends invalid class name' do
        expect { described_class.execute('MyWrongReport', '[true]') }
          .to raise_error(NameError)
      end

      it 'sends class that is not BaseReport successor' do
        expect { described_class.execute('Object', '[true]') }
          .to raise_error(RuntimeError)
      end
    end

    context 'when events are firing' do
      before do
        allow(described_class).to receive(:get_meta).and_return(OpenStruct.new)
        allow(described_class.get_meta).to receive(:save).and_return(true)
      end

      context 'when progress total is zero' do
        before do
          allow_any_instance_of(Reports::MyCsvReport::Query).to receive(:select_data).and_return([])
          allow_any_instance_of(Resque::Reports::Services::DataIterator).to receive(:data_size).and_return(0)
        end

        it { expect(described_class).to_not receive(:at) }

        after { described_class.execute(*exec_params) }
      end

      context 'when works default handlers' do
        context 'when error occurs' do
          before do
            allow(described_class).to receive(:get_meta).and_return(Hash.new)
            allow_any_instance_of(Resque::Reports::Services::TableBuilder).to receive(:build_row) { fail 'Custom Error'}
          end

          it do
            expect { described_class.execute(*exec_params) }
              .to raise_error(RuntimeError)
          end
        end

        context 'when progress is changed' do
          it { expect(described_class).to receive(:at).with(2, 2, 'Выгрузка отчета в CSV') }

          after { described_class.execute(*exec_params) }
        end
      end

      context 'when works custom handlers' do
        context 'when error occurs' do
          before do
            allow(my_report).to receive(:error_message) { |e| fail "Boom! #{e.message}" }
            allow(described_class).to receive(:get_meta).and_return(Hash.new)
            allow_any_instance_of(Resque::Reports::Services::TableBuilder).to receive(:build_row) { fail 'Custom Error'}
          end

          it { expect { described_class.execute(*exec_params) }.to raise_error(RuntimeError) }
        end

        context 'when progress is changed' do
          before do
            allow(my_report).to receive(:progress_message) do |progress, total|
              "my progress: #{progress} / #{total}"
            end
          end

          it { expect(described_class).to receive(:at).with(2, 2, 'my progress: 2 / 2') }

          after { described_class.execute(*exec_params) }
        end
      end

      context 'when task is performed by resque' do
        context 'when error occurs' do
          before do
            allow(described_class).to receive(:get_meta).and_return(Hash.new)
            allow(my_report).to receive(:error_message) { |e| fail "Boom! #{e.message}" }
            allow_any_instance_of(Resque::Reports::Services::TableBuilder).to receive(:build_row) { fail 'Custom Error'}
          end

          it { expect { described_class.execute(*exec_params) }.to raise_error(RuntimeError) }
        end
      end
    end
  end
end
