# coding: utf-8
require 'csv'

module Resque
  module Reports
    class CsvReport < BaseReport
      extend Forwardable
      include Callbacks # include on_progress, on_error callbacks, and handle_progress, handle_errors handlers

      class << self
        attr_accessor :options

        alias_method :csv_options, :options=
      end 

      DEFAULT_CSV_OPTIONS = { col_sep: ';', row_sep: "\r\n" }

      extension :csv

      def_delegators TO_EIGENCLASS, :options, :csv_options

      def initialize(*args)
        csv_options options ? DEFAULT_CSV_OPTIONS.merge(options) : DEFAULT_CSV_OPTIONS 
        super(*args)
      end

      # Callbacks
      on_progress { |progress, total| at(progress, total, progress_message(progress, total)) }
      on_error { |error| raise error }

      # You must use ancestor methods to work with data:
      #   1) get_data => returns Enumerable of source objects
      #   2) build_table_header => returns Array of column names
      #   3) build_table_row(object) => returns Array of cell values (same order as header)
      def write(io)        
        progress = 0

        CSV(io, options) do |csv|
          write_line csv, build_table_header

          data_each do |data_element|
            begin
              write_line csv, build_table_row(data_element)
            rescue
              handle_error
            end

            handle_progress(progress += 1)
          end

          handle_progress(progress, true)         
        end       
      end

      def write_line(csv, row_cells)
        csv << row_cells
      end
    end # class CsvReport
  end # module Report
end # module Resque
