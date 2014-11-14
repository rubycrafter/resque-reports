# coding: utf-8
require 'resque/reports/extensions/const'
require 'resque/reports/extensions/enqueue_to_fix'
require 'resque/reports/extensions/event_callbacks'
require 'resque/reports/extensions/event_templates'
require 'resque/reports/extensions/filename_gen'
require 'resque/reports/extensions/table_building'
require 'resque/reports/extensions/encodings'

# Resque namespace
module Resque
  # Resque::Reports namespace
  module Reports
    # Resque::Reports::Extensions namespace
    module Extensions
      # Class for dummy object that respond to any method
      # and returns 'nil' on any method call
      class Dummy
        def method_missing(method, *arguments, &block)
          nil
        end

        def respond_to?(method, include_private = false)
          true
        end
      end

      def self.included(base)
        base.send :include, Const # share gem constants
        base.send :include, TableBuilding # init and build table
        base.send :include, FilenameGen # generate_filename method
        base.send :include, EventCallbacks # event callbacks and handlers
        base.send :include, EventTemplates # template events handling methods
        base.send :include, Encodings # encoding constants
        base.send :include, EnqueueToFix # enqueue task to exact queue
      end
    end
  end
end
