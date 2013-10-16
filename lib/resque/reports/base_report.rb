# coding: utf-8
# Resque namespace
module Resque
  # Resque::Reports namespace
  module Reports
    # Class describes base report class for inheritance.
    # BaseReport successor must implement "write(io, force)" method
    # and may specify file extension with "extension" method call
    # example:
    #
    #   class CustomTypeReport < Resque::Reports::BaseReport
    #     extension :type # specify that report file must ends
    #                     # with '.type', e.g. 'abc.type'
    #
    #     # Method specifies how to output report data
    #     def write(io, force)
    #       io << 'Hello World!'
    #     end
    #   end
    #
    # BaseReport provides followed DSL, example:
    #
    #   class CustomReport < CustomTypeReport
    #     queue :custom_reports # Resque queue name
    #     source :select_data # method called to retrieve report data
    #     encoding UTF8 # file encoding
    #
    #     # Specify in which directory to keep this type files
    #     directory File.join(Dir.tmpdir, 'resque-reports')
    #
    #     # Describe table using 'column' method
    #     table do |element|
    #       column 'Column 1 Header', :decorate_one
    #       column 'Column 2 Header', decorate_two(element[1])
    #       column 'Column 3 Header', 'Column 3 Cell'
    #     end
    #
    #     # Class initialize
    #     # NOTE: must be used instead of define 'initialize' method
    #     create do |param|
    #       @main_param = param
    #     end
    #
    #     # decorate method, called by symbol-name
    #     def decorate_one(element)
    #       "decorate_one: #{element[0]}"
    #     end
    #
    #     # decorate method, called directly when filling cell
    #     def decorate_two(text)
    #       "decorate_two: #{text}"
    #     end
    #
    #     # method returns report data Enumerable
    #     def select_data
    #       [[0, 'text0'], [1, 'text1']]
    #     end
    #   end
    class BaseReport
      extend Forwardable
      include Extensions

      class << self

        attr_reader :job_queue

        protected

        attr_reader :create_block
        attr_writer :job_queue
        attr_accessor :file_extension,
                      :file_encoding,
                      :file_directory

        alias_method :super_extension, :file_extension
        alias_method :extension, :file_extension=
        alias_method :set_extension, :file_extension=
        alias_method :encoding, :file_encoding=
        alias_method :directory, :file_directory=
        alias_method :queue, :job_queue=

        def set_instance(obj)
          @instance = obj
        end

        def create(&block)
          @create_block = block
        end

        # override for Extenstions::TableBuilding, to use custom encoding
        def encoded_string(obj)
          obj.to_s.encode(file_encoding,
                          invalid: :replace,
                          undef: :replace)
        end

        #--
        # Hooks #
        #++

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

      #--
      # Constants #
      #++

      DEFAULT_EXTENSION = 'txt'

      #--
      # Delegators
      #++

      def_delegators Const::TO_EIGENCLASS,
                     :file_directory,
                     :file_extension,
                     :file_encoding,
                     :create_block,
                     :set_instance,
                     :set_extension

      def_delegators :@cache_file, :filename, :exists?, :ready?
      def_delegator Const::TO_SUPER, :super_extension

      #--
      # Public instance methods
      #++

      def initialize(*args)
        # TODO: Check consistance, fail if user initialized wrong object
        set_instance(self)

        if create_block
          define_singleton_method(:create_dispatch, create_block)
          create_dispatch(*args)
        end

        @args = args

        init_cache_file
        init_table
      end

      # Builds report synchronously
      def build(force = false)
        init_table if force

        @cache_file.open(force) { |file| write(file, force) }
      end

      # Builds report in background, returns job_id, to watch progress
      def bg_build(force = false)
        report_class = self.class.to_s

        args_json = [*@args, force].to_json

        # Check report if it already in progress and tring return its job_id...
        job_id = ReportJob.enqueued?(report_class, args_json).try(:meta_id)
        # ...and start new job otherwise
        job_id || ReportJob.enqueue(report_class, args_json).try(:meta_id)
      end

      protected

      def init_cache_file
        set_extension super_extension || DEFAULT_EXTENSION

        @cache_file = CacheFile.new(file_directory,
                                    generate_filename(@args, file_extension),
                                    coding: file_encoding)
      end

      # Method specifies how to output report data
      # @param [IO] io stream for output
      # @param [true, false] force write to output or skip due its existance
      def write(io, force)
        # You must use ancestor methods to work with report data:
        # 1) data_size => returns source data size (calls #count on data
        #                 retrieved from 'source')
        # 2) data_each => yields given block for each source data element
        # 3) build_table_header => returns Array of report column names
        # 4) build_table_row(object) => returns Array of report cell
        #                               values (same order as header)
        # 5) progress_message(progress,
        #                    total) => call to iterate job progress
        # 6) error_message(error) => call to handle error in job
        #
        # HINT: You may override data_size and data_each, to retrieve them
        #       effectively
        fail NotImplementedError
      end
    end # class BaseReport
  end # module Report
end # module Resque
