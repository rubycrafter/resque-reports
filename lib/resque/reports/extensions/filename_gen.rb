# coding: utf-8
module Resque
  module Reports
    module Extensions
      module FilenameGen
        private

        def generate_filename(args, fextension)
          "#{ hash(self.class.to_s, *args) }.#{ fextension }"
        end

        def hash(*args)
          Digest::SHA1.hexdigest(args.to_json)
        end
      end
    end
  end
end
