# coding: utf-8
require 'csv'

module Resque
  module Reports
    class CsvReport < BaseReport
      extend Forwardable

      class << self
        attr_accessor :options

        alias_method :csv_options, :options=
      end

      DEFAULT_CSV_OPTIONS = { col_sep: ';', row_sep: "\r\n" }

      extension :csv

      def_delegators TO_EIGENCLASS, :options, :csv_options

      def initialize(*args)
        csv_options(options ? DEFAULT_CSV_OPTIONS.merge(options) : DEFAULT_CSV_OPTIONS)

        super(*args)
      end

      # You must use ancestor methods to work with report data:
      #   1) data_size => returns source data size
      #   2) data_each => yields given block for each source data element
      #   3) build_table_header => returns Array of report column names
      #   4) build_table_row(object) => returns Array of report cell values (same order as header)
      def write(io, force = false)
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

      # Event handling #

      def error_handling(error)
        error_message = case error
                        when Encoding::UndefinedConversionError
                          "Символ #{error.error_char} не поддерживается заданной кодировкой"
                        when EncodingError
                          'Ошибка преобразования в заданную кодировку'
                        else
                          raise error
                        end

        meta = get_meta(@meta_id)
        meta['payload'] ||= { 'error_messages' => [] }
        meta['payload']['error_messages'] << "Выгрузка отчета невозможна. #{error_message}"
        meta.save
      end
    end # class CsvReport
  end # module Report
end # module Resque
