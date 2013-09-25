# coding: utf-8
module Resque
  module Reports
    class BaseReport
      # TODO: Hook initialize of successor to collect init params into @args array
      include ActiveSupport
      include Encodings # include encoding constants CP1251, UTF8...

      class << self
        protected

        attr_reader :row_object, :directory
        attr_accessor :extension, 
                      :encoding, 
                      :source_method, 
                      :table_block, 
                      :header_collecting
        
        alias_method :source_method, :source

        def table(&block)
          @table_block = block
        end

        def build_table_row(row_object)
          header_collecting = false

          @row_object = row_object
          row = @table_block.call(row_object)

          finish_row

          row
        end

        def build_table_header
          header_collecting = true
          @table_block.call(nil)
        end

        def get_data
          send(@source_method)
        end
      end # class methods

      DEFAULT_EXTENSION = 'txt'

      def initialize(*args)
        @args = args

        extension ||= DEFAULT_EXTENSION
        @cache_file = CacheFile.new(directory, generate_filename, coding: encoding)

        @table_header = []
        @table_row = []
      end

      def build
        @cache_file.open { |file| write file }
      end

      def bg_build
        report_class = class.to_s
        args_json = @args.to_json

        # Check report if it already in progress and tring return its job_id...
        job_id = ReportJob.enqueued?(report_class, args_json).try(:meta_id)
        
        # ...and start new job otherwise
        ReportJob.enqueue(report_class, args_json) unless job_id
      end

      delegate :filename, :exists?, :to => :cache_file

      protected

      # You must use ancestor methods to work with report data:
      #   1) get_data => returns Enumerable of report source objects
      #   2) build_table_header => returns Array of report column names
      #   3) build_table_row(object) => returns Array of report cell values (same order as header)
      def write(io)
        raise NotImplementedError, "write must be implemented in successor"          
      end
      
      def column(name, value)
        add_column_header(name) || add_column_cell(value)
      end

      private

      delegate :directory, 
               :extension, 
               :encoding,
               :get_data, 
               :build_table_header, 
               :build_table_row,
               :header_collecting, 
               :row_object,
               :to => 'self.class'
      
      def generate_filename
        "#{ self.class }-#{ hash_args }.#{ extension }"
      end

      def hash_args
        Digest::SHA1.hexdigest(@args.to_json)
      end

      def add_column_header(column_name)
        @table_header << column_name if header_collecting
      end

      def add_column_cell(column_value)
        return if header_collecting
        column_value = send(column_value, row_object) if column_value.is_a? Symbol
        @table_row << encoded_string(value)
      end

      def encoded_string(obj)
        obj.to_s.encode(encoding, :invalid => :replace, :undef => :replace)
      end

      def finish_row
        @table_row = []
      end
    end # class BaseReport
  end # module Report
end # module Resque
