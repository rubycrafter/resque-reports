require 'tempfile'
# coding: utf-8
module Resque
  module Reports
    # Class describes how to storage and access cache file
    # NOTE: Every time any cache file is opening,
    #       cache is cleared from old files.
    class CacheFile
      include Extensions::Encodings

      DEFAULT_EXPIRE_TIME = 86_400
      DEFAULT_CODING = UTF8

      def initialize(dir, filename, options = {})
        @dir = dir
        @filename = File.join(dir, filename)
        @ext = File.extname(filename)

        # options
        @coding = options[:coding] || DEFAULT_CODING
        @expiration_time = options[:expire_in] || DEFAULT_EXPIRE_TIME
      end

      def exists?
        File.exists?(@filename)
      end
      alias_method :ready?, :exists?

      def filename
        fail 'File doesn\'t exists, check exists? before' unless exists?
        @filename
      end

      def open(force = false)
        prepare_cache_dir

        (force ? clear : return) if File.exists?(@filename)

        with_tempfile do |tempfile|
          yield tempfile

          tempfile.close
          FileUtils.cp(tempfile.path, @filename)
        end
      end

      def clear
        FileUtils.rm_f(@filename)
      end

      protected

      def with_tempfile
        yield(tempfile = Tempfile.new(Digest::MD5.hexdigest(@filename), :encoding => @coding))
      ensure
        tempfile.close unless tempfile.closed?
        tempfile.try(:unlink)
      end

      def prepare_cache_dir
        FileUtils.mkdir_p @dir # create folder if not exists

        clear_expired_files
      end

      def clear_expired_files
        # TODO: avoid races when worker building
        #       his report longer than @expiration_time
        files_to_delete = cache_files_array.select { |fname| expired?(fname) }

        FileUtils.rm_f files_to_delete
      end

      def expired?(fname)
        File.file?(fname) && File.mtime(fname) + @expiration_time < Time.now
      end

      def cache_files_array
        Dir.new(@dir)
           .map { |fname| File.join(@dir, fname) if File.extname(fname) == @ext }
           .compact
      end
    end
  end
end
