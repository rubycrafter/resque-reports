# coding: utf-8
require 'resque/reports/common/batched_report'

module Resque
  module Reports
    module Common
      def self.included(base)
        base.send :include, BatchedReport
      end
    end
  end
end

