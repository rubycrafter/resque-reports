# coding: utf-8
module Resque
  module Reports
    module Common
      module BatchedReport
        extend ActiveSupport::Concern

        included do
          BATCH_SIZE = 10_000
        end

        # Internal: Подключение используемое для выполнения запросов
        #
        # Returns connection adapter
        def connection
          ActiveRecord::Base.connection
        end

        # Internal: Выполняет запрос отчета пачками и выполняет block для каждой пачки
        #   Переопредленный метод из Resque::Reports
        #
        # Returns Nothing
        def data_each(force = false)
          0.step(data_size, batch_size) do |batch_offset|
            connection.execute(batched_query(batch_offset)).each do |element|
              yield element
            end
          end
        end

        # Internal: Возвращает общее кол-во строк в отчете
        #   Переопредленный метод из Resque::Reports
        #
        # Returns Fixnum
        def data_size
          @data_size ||= connection.execute(count_query)[0]['count'].to_i
        end

        protected

        # Internal: Возвращает отфильтрованный запрос отчета
        #
        # Returns Arel::SelectManager
        def query
          filter base_query
        end

        # Internal: Полезный метод для хранения Arel::Table объектов для запроса отчета
        #
        # Returns Hash, {:table_name => #<Arel::Table @name="table_name">, ...}
        def tables
          return @tables if defined? @tables

          tables = models.map(&:arel_table)

          @tables = tables.reduce({}) { |a, e| a.store(e.name, e) && a }.with_indifferent_access
        end

        # Internal: Полезный метод для join'а необходимых таблиц через Arel
        #
        # Returns Arel
        def join_tables(source_table, *joins)
          joins.inject(source_table) { |query, joined| query.join(joined[:table]).on(joined[:on]) }
        end

        # Internal: Размер пачки отчета
        #
        # Returns Fixnum
        def batch_size
          BATCH_SIZE
        end

        # Internal: Модели используемые в отчете
        #
        # Returns Array of Arel::Table
        def models
          fail NotImplementedError
        end

        # Internal: Основной запрос отчета (Arel)
        #
        # Returns Arel::SelectManager
        def base_query
          fail NotImplementedError
        end

        # Internal: Поля запрашиваемые отчетом
        #
        # Returns String (SQL)
        def select
          fail NotImplementedError
        end

        # Internal: Порядок строк отчета
        #
        # Returns String (SQL)
        def order_by
          nil
        end

        # Internal: Фильтры отчета
        #
        # Returns Arel::SelectManager
        def filter(query)
          query
        end

        # Internal: Запрос количества строк в отчете
        #
        # Returns String (SQL)
        def count_query
          query.project(Arel.sql('COUNT(*) as count')).to_sql
        end

        # Internal: Запрос пачки строк отчета
        #
        #   offset - Numeric, число строк на которое сдвигается запрос
        #
        # Returns String (SQL)
        def batched_query(offset)
          query.project(Arel.sql(select))
               .take(batch_size)
               .skip(offset)
               .order(order_by)
               .to_sql
        end
      end
    end
  end
end