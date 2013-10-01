# coding: utf-8
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

      module Constants
        TO_EIGENCLASS = 'self.class'
      end
    end
  end
end
