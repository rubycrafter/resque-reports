# coding: utf-8
require 'spec_helper'
require 'resque-reports'

module Reports
  class MyCsvReport < Resque::Reports::CsvReport
    queue :csv_reports
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
end

describe Resque::Reports::ReportJob do
  let(:my_report) { Reports::MyCsvReport.new('.execute test', 'test') }
  let(:exec_params) do
    ['Reports::MyCsvReport', '[".execute test", "test",true]']
  end

  describe '.execute' do
    before { Reports::MyCsvReport.stub(new: my_report) }

    context 'when building report' do
      before { my_report.stub(build: nil) }

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
        described_class.stub(get_meta: {})
        described_class.get_meta.stub(save: true)
      end

      context 'when progress total is zero' do
        before do
          my_report.stub(select_data: [])
          my_report.stub(data_size: 0)
        end

        it { described_class.should_not_receive(:at) }

        after { described_class.execute(*exec_params) }
      end

      context 'when works default handlers' do
        context 'when error occurs' do
          before { my_report.stub(:build_table_row) { fail 'Custom error' } }

          it do
            expect { described_class.execute(*exec_params) }
              .to raise_error('Custom error')
          end
        end

        context 'when progress is changed' do
          it { described_class.should_receive(:at).with(2, 2, nil) }

          after { described_class.execute(*exec_params) }
        end
      end

      context 'when works custom handlers' do
        context 'when error occurs' do
          before do
            my_report.stub(:error_message) { |e| fail "Boom! #{e.message}" }
            my_report.stub(:build_table_row) { fail 'Custom error' }
          end

          it do
            expect { described_class.execute(*exec_params) }
              .to raise_error('Boom! Custom error')
          end
        end

        context 'when progress is changed' do
          before do
            my_report.stub(:progress_message) do |progress, total|
              "my progress: #{progress} / #{total}"
            end
          end

          it do
            described_class
              .should_receive(:at)
              .with(2, 2, 'my progress: 2 / 2')
          end

          after { described_class.execute(*exec_params) }
        end
      end

      context 'when task is performed by resque' do
        context 'when error occurs' do
          before do
            my_report.stub(:error_message) { |e| fail "Boom! #{e.message}" }
            my_report.stub(:build_table_row) { fail 'Custom error' }
          end

          it do
            expect { described_class.execute(*exec_params) }
              .to raise_error('Boom! Custom error')
          end
        end
      end
    end
  end
end
