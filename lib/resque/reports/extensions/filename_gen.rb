# coding: utf-8
module Resque
  module Reports
    module Extensions
      # Module that generates file name
      # Usage:
      #   class SomeClass
      #     include Resque::Reports::Extensions::FilenameGen
      #
      #     # ...call somewhere...
      #     fname = generate_filename(%w(a b c), 'pdf')
      #     # 'fname' value is something like this:
      #     #   "a60428ee50f1795819b8486c817c27829186fa40.pdf"
      #   end
      module FilenameGen

        DEFAULT_EXTENSION = 'txt'

        private

        def generate_filename(args, fextension)
          "#{ hash(self.class.to_s, *args) }.#{ fextension || DEFAULT_EXTENSION }"
        end

        def hash(*args)
          Digest::SHA1.hexdigest(args.to_json)
        end
      end
    end
  end
end
