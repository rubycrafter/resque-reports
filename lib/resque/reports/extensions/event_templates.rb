# coding: utf-8
module Resque
  module Reports
    module Extensions
      # Defines base event handling methods for Resque::Reports::EventCallbacks
      module EventTemplates

        # Specifies progress message generation
        # Can be overridden in successors
        def progress_message(p, t)
          nil
        end

        # Specifies error message generation
        # Can be overridden in successors
        def error_message(e)
          fail e
        end
      end
    end
  end
end
