module Resque
  module Reports
    module Extensions
      module Config
        DEFAULT_QUEUE = :reports

        def queue
          @queue ||= DEFAULT_QUEUE
        end

        def self.included(base)
          base.class_eval do
            def self.config_attributes
              super + [:queue]
            end
          end
        end
      end
    end
  end
end
