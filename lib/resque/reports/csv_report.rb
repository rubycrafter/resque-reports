# coding: utf-8
require 'csv'

module Resque
  module Reports
    # Class to inherit from for custom CSV reports
    # To make your custom report you must define at least:
    #   1. directory, is where to write reports to
    #   2. source, is symbol of method that retrieves report data
    #   3. table, report table configuration using DSL
    class CsvReport < BaseReport
      extend Forwardable

      class << self
        attr_accessor :options

        alias_method :csv_options, :options=
      end

      DEFAULT_CSV_OPTIONS = {col_sep: ';', row_sep: "\r\n"}

      extension :csv

      def_delegators TO_EIGENCLASS, :options, :csv_options

      def initialize(*args)
        csv_options DEFAULT_CSV_OPTIONS.merge(options || Hash.new)

        super(*args)
      end

      def write(io, force = false)
        # You must use ancestor methods to work with report data:
        #   1) data_size => returns source data size
        #   2) data_each => yields given block for each source data element
        #   3) build_table_header => returns Array of report column names
        #   4) build_table_row(object) => returns Array of report cell values
        #                                 (same order as header)
        progress = 0

        CSV(io, options) do |csv|
          write_line csv, build_table_header

          data_each(force) do |data_element|
            begin
              write_line csv, build_table_row(data_element)
            rescue
              handle_error
            end

            handle_progress(progress += 1, data_size)
          end

          handle_progress(progress, data_size, true)
        end
      end

      def write_line(csv, row_cells)
        csv << row_cells
      end

      #--
      # Event handling #
      #++

      def error_message(error)
        error_message = []
        error_message << 'Выгрузка отчета невозможна. '
        error_message << case error
                         when Encoding::UndefinedConversionError
                           <<-ERR_MSG.gsub(/^ {29}/, '')
                             Символ #{error.error_char} не поддерживается
                             заданной кодировкой
                           ERR_MSG
                         when EncodingError
                           'Ошибка преобразования в заданную кодировку'
                         else
                           fail error
                         end
        error_message * ' '
      end
    end # class CsvReport
  end # module Report
end # module Resque
