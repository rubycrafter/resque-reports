# coding: utf-8
module Resque
  module Reports
    module Callbacks

      # TODO: сделать гибкой логику колбеков и хендлеров
    	module ClassMethods
    	  PROGRESS_INTERVAL = 10

        # Callbacks

        # rubocop:disable TrivialAccessors

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

        # rubocop:enable TrivialAccessors

        # Handlers
        def handle_progress(progress, force = false)
          if @progress_callback && (force || progress % self.class::PROGRESS_INTERVAL == 0)
            @progress_callback.call progress, @data.size
          end
        end

        def handle_error
          @error_callback ? @error_callback.call($ERROR_INFO) : raise
        end
      end    	
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
