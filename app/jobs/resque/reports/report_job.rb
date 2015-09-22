# coding: utf-8
require 'json'
require 'active_support/inflector'

module Resque
  module Reports
    # ReportJob accepts report_type, its arguments in json
    # and building report in background
    # @example:
    #
    #    ReportJob.enqueue('Resque::Reports::MyReport', [1, 2].to_json)
    #    ReportJob.enqueue_to(:my_queue, 'Resque::Reports::MyReport', [1, 2].to_json)
    #
    class ReportJob
      include Resque::Integration
      extend Patches::EnqueueTo

      unique

      # resque-integration main job method
      # @param [String] report_type - name of BaseReport successor
      #                 to build report for
      # @param [String(JSON)] args_json - json array of report arguments
      def self.execute(report_type, args_json)
        report_class = report_type.constantize # избавиться от ActiveSupport

        args = JSON.parse(args_json)
        force = args.pop

        init_report(report_class, args).build(force)
      end

      # Initializes report of given class with given arguments
      def self.init_report(report_class, args_array)
        report = report_class.new(*args_array)

        report.progress_handler do |progress, total|
          unless total.zero?
            at(progress, total, report.progress_message(progress, total))
          end
        end

        report.error_handler do |error|
          meta = get_meta(@meta_id)
          meta['payload'] ||= {'error_messages' => []}
          meta['payload']['error_messages'] << report.error_message(error)
          meta.save
        end

        report
      end
    end # class ReportJob
  end # module Reports
end # module Resque
