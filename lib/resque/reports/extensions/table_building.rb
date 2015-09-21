require 'active_support/core_ext/hash/indifferent_access'
# coding: utf-8
# Resque namespace
module Resque
  # Resque::Reports namespace
  module Reports
    # Resque::Reports::Extensions namespace
    module Extensions
      # Defines report table building logic
      module TableBuilding
        # Defines table building methods
        #   External(DSL):
        #     - source
        #     - table
        #     - column
        #   Internal:
        #     - init_table
        #     - build_table_header
        #     - build_table_row(row_object)
        #     - data_each
        #     - data_size
        module ClassMethods
          attr_accessor :source_method
          alias_method :source, :source_method=

          def table(&block)
            @table_block = block
          end

          def column(name, value, options = {})
            if options[:skip_if].present?
              if options[:skip_if].is_a?(Symbol)
                return if @instance.send(options.delete(:skip_if))
              elsif options[:skip_if].respond_to?(:call)
                return if options.delete(:skip_if).call
              end
            end
            add_column_header(name) || add_column_cell(value, options)
          end

          def init_table
            @table_header = []
            @table_row = []
          end

          def add_column_header(column_name)
            @table_header << encoded_string(column_name) if @header_collecting
          end

          def add_column_cell(column_value, options = {})
            return if @header_collecting

            if column_value.is_a? Symbol
              column_value = if @row_object.respond_to?(column_value)
                               @row_object.public_send(column_value)
                             else
                               @row_object[column_value]
                             end
            end

            if (formatter_name = options[:formatter])
              column_value = @instance.send("#{formatter_name}_formatter".to_sym, column_value)
            end

            @table_row << encoded_string(column_value)
          end

          def build_table_row(row_object)
            @header_collecting = false

            @row_object = row_object.is_a?(Hash) ? row_object.with_indifferent_access : row_object

            row = @table_block.call(@row_object)

            finish_row

            row
          end

          def build_table_header
            @header_collecting = true
            @table_block.call(Extensions::Dummy.new)
          end

          # you may override default string endcoding
          def encoded_string(obj)
            obj.to_s.encode('utf-8', invalid: :replace, undef: :replace)
          end

          def finish_row
            @table_row = []
          end

          def data(force = false)
            if force || @data.nil?
              @data = @instance.send(@source_method)
            else
              @data
            end
          end

          def data_each(force = false)
            data(force).each do |element|
              yield element
            end
          end

          def data_size
            @data_size ||= data.count
          end
        end

        # Delegates class methods to instance
        module InstanceMethods
          extend Forwardable

          def_delegators Extensions::Const::TO_EIGENCLASS,
                         :data_each,
                         :data_size,
                         :build_table_header,
                         :build_table_row,
                         :init_table
        end

        def self.included(base)
          base.extend ClassMethods
          base.send :include, InstanceMethods
        end
      end
    end
  end
end
