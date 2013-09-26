# coding: utf-8
module Resque
  module Reports
    class CacheFile

      DEFAULT_EXPIRE_TIME = 86400
      DEFAULT_CODING = 'utf-8'

      # TODO: Description!
      def initialize(dir, filename, options = {})
        @dir = dir
        @filename = File.join(dir, filename)

        # options
        @coding = options[:coding] || DEFAULT_CODING
        @expiration_time = options[:expire_in] || DEFAULT_EXPIRE_TIME
      end

      def exists?
        File.exists?(@filename)
      end
      alias_method :exists?, :ready?

      def filename
        raise "File doesn't exists, check for its existance before" unless exists?
        @filename
      end

      def open
        prepare_cache_dir

        remove_unfinished_on_error do
          File.open(@filename, @coding) do |file|
            yield file
          end
        end
      end

      protected

      def prepare_cache_dir
        FileUtils.mkdir_p @dir # create folder if not exists

        clear_expired_files
      end

      def clear_expired_files
        # TODO: avoid races when worker building his report longer than @expiration_time
        files_to_delete = cache_files_array.select { |fname| expired?(fname) }

        FileUtils.rm_f files_to_delete
      end

      def expired?(fname)
        File.file?(fname) && File.mtime(fname) + @expiration_time < Time.now
      end

      def cache_files_array
        Dir.new(@dir).map { |fname| File.join(@dir.path, fname) }
      end

      def remove_unfinished_on_error
        yield
      rescue => error
        FileUtils.rm_f @filename # remove everything that was written due to it inconsistance
        raise error # don't suppress any errors here
      end
    end
  end
end
