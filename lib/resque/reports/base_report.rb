# coding: utf-8
module Resque
  module Reports
    class BaseReport
      extend Forwardable
      include Extensions      

      class << self
        protected

        attr_reader :create_block
        attr_accessor :file_extension,
                      :file_encoding,
                      :file_directory

        alias_method :extension, :file_extension=
        alias_method :encoding, :file_encoding=
        alias_method :directory, :file_directory=

        def set_instance(obj)
          @instance = obj
        end

        def create(&block)
          @create_block = block
        end

        # override for Extenstions::TableBuilding, to use custom encoding
        def encoded_string(obj)
          obj.to_s.encode(file_encoding, :invalid => :replace, :undef => :replace)
        end

        # Hooks #

        def method_missing(method_name, *args, &block)
          if @instance.respond_to?(method_name)
            @instance.send(method_name, *args, &block)
          else
            super
          end
        end

        def respond_to?(method, include_private = false)
          super || @instance.respond_to?(method, include_private)
        end
      end # class methods

      # Constants #

      DEFAULT_EXTENSION = 'txt'

      # Delegators #

      def_delegators Const::TO_EIGENCLASS,
                     :file_directory,
                     :file_extension,
                     :file_encoding,
                     :create_block,
                     :set_instance,
                     :extension

      def_delegators :@cache_file, :filename, :exists?, :ready?

      # Public instance methods #

      def initialize(*args)
        # TODO: Check consistance, if user initialized wrong object
        set_instance(self)

        if create_block
          define_singleton_method(:create_dispatch, create_block)
          create_dispatch *args
        end

        @args = args
        # self.class.superclass - is VERY VERY ugly! Refactor me, please!
        extension self.class.superclass.send(:file_extension) || DEFAULT_EXTENSION

        @cache_file = CacheFile.new(file_directory, generate_filename(args, file_extension), coding: file_encoding)

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

      protected

      # You must use ancestor methods to work with report data:
      #   1) data_size => returns source data size
      #   2) data_each => yields given block for each source data element
      #   3) build_table_header => returns Array of report column names
      #   4) build_table_row(object) => returns Array of report cell values (same order as header)
      def write(io, force)
        raise NotImplementedError, "write must be implemented in successor"
      end
    end # class BaseReport
  end # module Report
end # module Resque
