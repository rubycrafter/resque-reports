# coding: utf-8
require 'facets/kernel/constant'
require 'json'

module Resque
  module Reports
    # ReportJob accepts report_type and current report arguments to build it in background
    class ReportJob
      include Resque::Integration

      queue :base
      unique { |report_type, args_json| [report_type, args_json] }

      def self.execute(report_type, args_json)
        report_class = constant(report_type) # Get report class from string (through ActiveSupport)
        raise "Resque::Reports::ReportJob can work only with successors of Resque::Reports::BaseReport, but got #{report_class}" unless report_class.ancestors.include? BaseReport

        args = JSON.parse(args_json)
        force = args.pop

        report = report_class.new *args
        
        report.build(force)
      end
    end # class ReportJob
  end # module Reports
end # module Resque
