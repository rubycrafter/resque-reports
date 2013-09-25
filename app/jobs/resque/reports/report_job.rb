# coding: utf-8
module Resque
  module Reports
    # ReportJob accepts report_type and current report arguments to build it in background
    class ReportJob
      include Resque::Integration
      include ActiveSupport

      queue :reports
      unique { |report_type, args_json| [report_type, args_json] }

      def self.execute(report_type, args_json)
        report_class = report_type.constantize # Get report class from string (through ActiveSupport)
        raise "Resque::Reports::ReportJob can work only with successors of Resque::Reports::BaseReport, but got #{report_class}" unless report_class.ancestors.include? BaseReport

        args = Json.parse(args_json)
        report = report_class.new *args

        report.build
      end
    end # class ReportJob
  end # module Reports
end # module Resque
