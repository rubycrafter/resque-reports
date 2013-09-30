# coding: utf-8
module Resque
  module Reports
    class BaseReport
      # TODO: Hook initialize of successor to collect init params into @args array
      extend Forwardable
      include Encodings # include encoding constants CP1251, UTF8...
      include Callbacks # include on_progress, on_error callbacks, and handle_progress, handle_errors handlers

      class << self
        protected

        attr_reader :row_object,
                    :create_block,
                    :table_block,
                    :header_collecting

        attr_accessor :file_extension,
                      :file_encoding,
                      :file_directory,
                      :source_method

        alias_method :source, :source_method=
        alias_method :extension, :file_extension=
        alias_method :encoding, :file_encoding=
        alias_method :directory, :file_directory=

        def set_instance(obj)
          @instance = obj
        end

        def get_instance
          @instance
        end

        def table(&block)
          @table_block = block
        end

        def create(&block)
          @create_block = block
        end

        def build_table_row(row_object)
          @header_collecting = false

          @row_object = row_object # for instance decorate methods calls
          row = @table_block.call(row_object)

          finish_row

          row
        end

        def build_table_header
          @header_collecting = true
          @table_block.call(Extensions::Dummy.new)
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

        # Fill report table #

        def column(name, value)
          add_column_header(name) || add_column_cell(value)
        end

        def init_table
          @table_header = []
          @table_row = []
        end

        def add_column_header(column_name)
          @table_header << column_name if header_collecting
        end

        def add_column_cell(column_value)
          return if header_collecting
          column_value = @instance.send(column_value, row_object) if column_value.is_a? Symbol
          @table_row << encoded_string(column_value)
        end

        def encoded_string(obj)
          obj.to_s.encode(file_encoding, :invalid => :replace, :undef => :replace)
        end

        def finish_row
          @table_row = []
        end

        # extra

        def method_missing(method_name, *args, &block)
          if get_instance.respond_to?(method_name)
            get_instance.send(method_name, *args, &block)
          else
            super
          end
        end

        def respond_to?(method, include_private = false)
          super || get_instance.respond_to?(method, include_private)
        end
      end # class methods

      # Constants #

      DEFAULT_EXTENSION = 'txt'
      TO_EIGENCLASS = 'self.class'

      def_delegators TO_EIGENCLASS,
                     :file_directory,
                     :file_extension,
                     :file_encoding,
                     :data_each,
                     :data_size,
                     :build_table_header,
                     :build_table_row,
                     :create_block,
                     :init_table,
                     :set_instance,
                     :get_instance,
                     :extension,
                     :on_progress,
                     :on_error

      # Public instance methods #

      def initialize(*args)
        # TODO: Check consistance, if user initialized wrong object

        set_instance(self)

        if create_block
          define_singleton_method(:create_dispatch, create_block)
          create_dispatch *args
        end

        @args = args
        extension self.class.superclass.send(:file_extension) || DEFAULT_EXTENSION

        @cache_file = CacheFile.new(file_directory, generate_filename, coding: file_encoding)

        init_table
      end

      def build(force = false)
        init_table if force

        @cache_file.open(force) { |file| write(file, force) }
      end

      def bg_build(force = false)
        report_class = self.class.to_s

        @args << force
        args_json = @args.to_json

        # Check report if it already in progress and tring return its job_id...
        job_id = ReportJob.enqueued?(report_class, args_json).try(:meta_id)

        # ...and start new job otherwise
        job_id || ReportJob.enqueue(report_class, args_json).try(:meta_id)
      end

      def_delegators :@cache_file, :filename, :exists?

      # Can be overridden in successors
      def progress_message(p,t)
        nil
      end

      # Can be overridden in successors
      def error_handling(e)
        raise e
      end

      protected

      # You must use ancestor methods to work with report data:
      #   1) data_size => returns source data size
      #   2) data_each => yields given block for each source data element
      #   3) build_table_header => returns Array of report column names
      #   4) build_table_row(object) => returns Array of report cell values (same order as header)
      def write(io, force)
        raise NotImplementedError, "write must be implemented in successor"
      end



      private

      # Generate filename #

      def generate_filename
        "#{ hash_args }.#{ file_extension }"
      end

      def hash_args
        Digest::SHA1.hexdigest("#{self.class}-#{@args.to_json}")
      end
    end # class BaseReport
  end # module Report
end # module Resque
