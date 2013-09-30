# coding: utf-8
module Resque
  module Reports
    module Extensions
      # Copy-paste from 'facets/kernel/constant' is made to prevent method override
      def self.constant(const)
        const = const.to_s.dup
        base = const.sub!(/^::/, '') ? Object : ( self.kind_of?(Module) ? self : self.class )
        const.split(/::/).inject(base){ |mod, name| mod.const_get(name) }
      end

      class Dummy
        def method_missing(method, *arguments, &block)
          nil
        end

        def respond_to?(method, include_private = false)
          true
        end
      end
    end
  end
end
