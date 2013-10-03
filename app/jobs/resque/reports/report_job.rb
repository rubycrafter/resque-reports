# coding: utf-8
require 'json'
require 'active_support'

module Resque
  module Reports
    # ReportJob accepts report_type and current report arguments to build it in background
    class ReportJob
      include Resque::Integration

      queue :base # TODO: change queue to work separetly
      unique

      def self.execute(report_type, args_json)
        report_class = report_type.constantize # избавиться от зависимости ActiveSupport
        raise "Resque::Reports::ReportJob can work only with successors of Resque::Reports::BaseReport, but got #{report_class}" unless report_class.ancestors.include? BaseReport

        args = JSON.parse(args_json)
        force = args.pop

        report = report_class.new *args

        report_class.on_progress { |progress, total| at(progress, total, report.progress_message(progress,total)) unless total.zero? }
        report_class.on_error { |error| report.error_handling(error) }

        report.build(force)
      end
    end # class ReportJob
  end # module Reports
end # module Resque
