# coding: utf-8
module Resque
  module Reports
    module Extensions
      module EventTemplates
        # Events handling:
        #   * You may use @meta_id and get_meta inside, which are defined by Resque

        # Can be overridden in successors
        def progress_message(p,t)
          nil
        end

        # Can be overridden in successors
        def error_handling(e)
          raise e
        end
      end
    end
  end
end
