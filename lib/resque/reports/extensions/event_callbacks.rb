# coding: utf-8
module Resque
  module Reports
    module Extensions
      # Defines event callbacks and handlers for Resque::Reports::ReportJob
      module EventCallbacks
        # TODO: сделать гибкой логику колбеков и хендлеров
        # Defines callbacks
        module ClassMethods

          attr_reader :progress_callback, :error_callback

          #--
          # Callbacks
          #++

          # Set callback for watching progress of export
          # @yield [progress] block to be executed on progress
          # @yieldparam progress [Integer] current progress
          # @yieldparam total [Integer] data length
          def on_progress(&block)
            @progress_callback = block
          end

          # Set callback on error
          # @yield [error] block to be executed when error occurred
          # @yieldparam [Exception] error
          def on_error(&block)
            @error_callback = block
          end
        end

        # Defines handlers
        module InstanceMethods
          extend Forwardable

          PROGRESS_STEP = 10

          def_delegators Extensions::Const::TO_EIGENCLASS,
                         :error_callback,
                         :progress_callback
          #--
          # Handlers
          #++

          def handle_progress(progress, total, force = false)
            if progress_callback && (force || progress % PROGRESS_STEP == 0)
              progress_callback.call progress, total
            end
          end

          def handle_error
            error_callback ? error_callback.call($ERROR_INFO) : fail
          end
        end

        def self.included(base)
          base.extend ClassMethods
          base.send :include, InstanceMethods
        end
      end
    end
  end
end
