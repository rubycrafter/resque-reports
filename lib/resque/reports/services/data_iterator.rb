module Resque
  module Reports
    module Services
      class DataIterator
        attr_reader :custom_source
        pattr_initialize :query, :config do
          @custom_source = query.send(config.source) if config.source
        end

        def iterate_data_source
          custom_source.each do |row|
            yield row
          end
        end
        # Internal: Выполняет запрос строк отчета пачками
        #
        # Returns Nothing
        def data_each(force = false, &block)
          return iterate_data_source(&block) if custom_source

          batch_offset = 0

          while (rows = execute_batched_query(batch_offset)).size > 0 do
            rows.each { |row| yield row }
            batch_offset += config.batch_size
          end
        end

        # Internal: Возвращает общее кол-во строк в отчете
        #
        # Returns Fixnum
        def data_size
          @data_size ||= custom_source.try(:size) || query.execute(query.count)[0]['count'].to_i
        end

        # Internal: Запрос пачки строк отчета
        #
        #   offset - Numeric, число строк на которое сдвигается запрос
        #
        # Returns String (SQL)
        def execute_batched_query(offset)
          query.execute query.take_batch(config.batch_size, offset)
        end
      end
    end
  end
end
