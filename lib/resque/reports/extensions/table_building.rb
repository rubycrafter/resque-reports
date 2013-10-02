# coding: utf-8
module Resque
  module Reports
    module Extensions
      module TableBuilding
        module ClassMethods

          attr_accessor :source_method
          alias_method :source, :source_method=

          def table(&block)
            @table_block = block
          end

          def column(name, value)
            add_column_header(name) || add_column_cell(value)
          end

          def init_table
            @table_header = []
            @table_row = []
          end

          def add_column_header(column_name)
            @table_header << encoded_string(column_name) if @header_collecting
          end

          def add_column_cell(column_value)
            return if @header_collecting
            column_value = @instance.send(column_value, @row_object) if column_value.is_a? Symbol
            @table_row << encoded_string(column_value)
          end

          def build_table_row(row_object)
            @header_collecting = false

            @row_object = row_object # for instance decorate methods calls
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
            obj.to_s.encode('utf-8', :invalid => :replace, :undef => :replace)
          end

          def finish_row
            @table_row = []
          end

          def data_each(force = false)
            @data = @instance.send(@source_method) if force || @data.nil?

            @data.each do |element|
              yield element
            end
          end

          def data_size
            @data_size ||= @data.count
          end
        end

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
