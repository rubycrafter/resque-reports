require 'facets/kernel/try'

# coding: utf-8
module Ruby
  module Reports
    class BaseReport
      class << self
        def build(options = {})
          in_background = options.delete(:background)
          force = options.delete(:force)
          report = new(options)

          in_background ? report.bg_build(force) : report.build(force)

          report
        end
      end

      attr_reader :job_id

      # Builds report in background, returns job_id, to watch progress
      def bg_build(force = false)
        report_class = self.class.to_s

        args_json = [*args, force].to_json

        # Check report if it already in progress and tring return its job_id...
        @job_id = Resque::Reports::ReportJob.enqueued?(report_class, args_json).try(:meta_id)

        # ...and start new job otherwise
        @job_id ||= Resque::Reports::ReportJob.enqueue_to(config.queue, report_class, args_json).try(:meta_id)
      end
    end # class BaseReport
  end # module Report
end # module Resque
