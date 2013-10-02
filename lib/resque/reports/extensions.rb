# coding: utf-8
require 'resque/reports/extensions/const'
require 'resque/reports/extensions/event_callbacks'
require 'resque/reports/extensions/event_templates'
require 'resque/reports/extensions/filename_gen'
require 'resque/reports/extensions/table_building'
require 'resque/reports/extensions/encodings'

module Resque
  module Reports
    module Extensions
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
        base.send :include, EventCallbacks # include on_progress, on_error callbacks, and handle_progress, handle_errors handlers
        base.send :include, EventTemplates # simple events handling methods with description
        base.send :include, Encodings # include encoding constants CP1251, UTF8...
      end
    end
  end
end
