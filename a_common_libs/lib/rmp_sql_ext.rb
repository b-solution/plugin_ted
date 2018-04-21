module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        args * ' + '
      end

      def rmp_char_length(column)
        "CHAR_LENGTH(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "SUBSTRING(#{column}, #{start_index}, #{length})"
      end

      def rmp_current_time
        "CURDATE()"
      end

      def rmp_days_diff(start_date, end_date)
        "EXTRACT(DAY FROM #{end_date} - #{start_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "EXTRACT(SECOND FROM #{end_date} - #{start_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end


      def rmp_get_date(field)
        "DATE(#{field})"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_date_iso(field)
        "DATE_FORMAT(#{field}, '%Y-%m-%d')"
      end

      def rmp_add_month(field, num)
        "DATE_ADD(#{field}, INTERVAL #{num} MONTH)"
      end
    end

    class AbstractMysqlAdapter < AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        "CONCAT(#{args * ', '})"
      end

      def rmp_char_length(column)
        "CHAR_LENGTH(#{column})"
      end

      def rmp_substring(column, start_index, length)
        start_index = 1 if start_index == 0
        "SUBSTRING(#{column}, #{start_index}, #{length})"
      end

      def rmp_current_time
        'CURDATE()'
      end

      def rmp_days_diff(start_date, end_date)
        "TIMESTAMPDIFF(DAY, #{start_date}, #{end_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "TIMESTAMPDIFF(SECOND, #{start_date}, #{end_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end

      def rmp_get_date(field)
        "DATE(#{field})"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_date_iso(field)
        "DATE_FORMAT(#{field}, '%Y-%m-%d')"
      end

      def rmp_add_month(field, num)
        "DATE_ADD(#{field}, INTERVAL #{num} MONTH)"
      end
    end

    class SQLServerAdapter < AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        args * ' + '
      end

      def rmp_char_length(column)
        "LEN(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "SUBSTRING(#{column}, #{start_index}, #{length})"
      end

      def rmp_current_time
        'NOW()'
      end

      def rmp_days_diff(start_date, end_date)
        "DATEDIFF(day, #{start_date}, #{end_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "DATEDIFF(second, #{start_date}, #{end_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end

      def rmp_get_date(field)
        "CAST(#{field} AS DATE)"
      end

      def rmp_date_iso(field)
        "CONVERT(nvarchar, #{field}, 23)"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_add_month(field, num)
        "DATEADD(month, #{num}, #{field})"
      end
    end

    class PostgreSQLAdapter < AbstractAdapter
      def rmp_random
        'random()'
      end

      def rmp_concat(*args)
        args * ' || '
      end

      def rmp_char_length(column)
        "char_length(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "substring(#{column} from #{start_index} for #{length})"
      end

      def rmp_current_time
        'NOW()'
      end

      def rmp_days_diff(start_date, end_date)
        "DATE_PART('day', (#{end_date})::date - (#{start_date})::date)"
      end

      def rmp_seconds_diff(start_date, end_date)
        "EXTRACT(EPOCH FROM (#{end_date})::timestamp - (#{start_date})::timestamp)"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as INTEGER)"
      end

      def rmp_get_date(field)
        "(#{field})::timestamp::date"
      end

      def rmp_get_datetime(field)
        "(#{field})::timestamp"
      end

      def rmp_date_iso(field)
        "to_char((#{field})::date, 'YYYY-mm-dd')"
      end

      def rmp_add_month(field, num)
        "(#{field}::timestamp + '#{num} month'::interval)"
      end
    end
  end

  module Associations
    class JoinDependency
      class JoinAssociation
        def build_constraint_with_rmp(klass, table, key, foreign_table, foreign_key)
          if foreign_table.present? && table.present?
            bclass = table.name.classify.safe_constantize
            foreign_bclass = foreign_table.name.classify.safe_constantize

            if bclass && foreign_bclass
              proc_name = "conditions_over_on_#{table.name}_#{key}_#{foreign_table.name}_#{foreign_key}"

              if bclass.respond_to?(proc_name)
                table = table.clone
                table.condition_over = bclass.send(proc_name)
              end

              proc_name = "conditions_over_on_#{foreign_table.name}_#{foreign_key}_#{table.name}_#{key}"

              if foreign_bclass.respond_to?(proc_name)
                foreign_table = foreign_table.clone
                foreign_table.condition_over = foreign_bclass.send(proc_name)
              end
            end
          end

          build_constraint_without_rmp(klass, table, key, foreign_table, foreign_key)
        end

        alias_method_chain :build_constraint, :rmp
      end
    end
  end
end

module Arel
  class Table
    attr_accessor :condition_over
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Attributes_Attribute o, collector
        join_name = o.relation.table_alias || o.relation.name
        if o.relation.respond_to?(:condition_over) && o.relation.condition_over.is_a?(Proc)
          res = o.relation.condition_over.call(o, "#{quote_table_name join_name}.#{quote_column_name o.name}").to_s
        else
          res = "#{quote_table_name join_name}.#{quote_column_name o.name}"
        end

        if Arel::VERSION.to_s > '6.0.0'
          collector << res
        else
          res
        end
      end
    end
  end
end