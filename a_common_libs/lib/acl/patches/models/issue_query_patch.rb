module Acl::Patches::Models
  module IssueQueryPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        alias_method_chain :issues, :acl
      end
    end

    module InstanceMethods
      # must be last in alias_method_chain call stack, eg. first defined
      def issues_with_acl(options={})
        order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

        scope = Issue.visible.
            joins(:status, :project).
            preload(:priority).
            where(statement).
            includes(([:status, :project] + (options[:include] || [])).uniq).
            where(options[:conditions]).
            order(order_option).
            joins(joins_for_order_statement(order_option.join(','))).
            limit(options[:limit]).
            offset(options[:offset])

        scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))

        # detect list of CFs to display
        query_cfs = columns.select { |column| column.is_a?(QueryCustomFieldColumn) }
        if (grp_column = group_by_column).present? && grp_column.is_a?(QueryCustomFieldColumn)
          query_cfs << grp_column
        end
        query_cfs = query_cfs.map { |c| c.custom_field.id }

        adapter_type = Issue.connection.adapter_name.downcase.to_sym
        case adapter_type
          when :mysql, :mysql2, :postgresql, :sqlserver
            issues = scope.to_a

            if query_cfs.present? && issues.any?
              ids = issues.map(&:id)

              case adapter_type
                when :mysql, :mysql2
                  cvs = CustomValue.joins("INNER JOIN
                                                (
                                                  SELECT cv.id,
                                                         cv.cnt,
                                                         cv.field_format
                                                  FROM
                                                  (
                                                    SELECT cv.id,
                                                           cv_m.cnt,
                                                           cf.field_format,
                                                           @row_num := if (@previous = CONCAT(i.id, '_', cf.id) and cf.multiple = #{Issue.connection.quoted_true} and cf.acl_trim_multiple = #{Issue.connection.quoted_true}, @row_num + 1, 1) row_number,
                                                           @previous := CONCAT(i.id, '_', cf.id)
                                                    FROM custom_values cv
                                                         INNER JOIN issues i on i.id = cv.customized_id
                                                         INNER JOIN custom_fields cf on cf.id = cv.custom_field_id
                                                         INNER JOIN (SELECT COUNT(1) as cnt, cv.custom_field_id, cv.customized_id FROM custom_values cv WHERE cv.customized_type = 'Issue' and cv.custom_field_id IN (#{query_cfs.join(',')}) and cv.customized_id IN (#{ids.join(',')}) GROUP BY cv.custom_field_id, cv.customized_id) cv_m on cv_m.custom_field_id = cf.id and cv_m.customized_id = i.id
                                                         CROSS JOIN (select @row_num := 0, @previous := null) tmp_vars
                                                    WHERE cv.customized_type = 'Issue'
                                                      and cv.custom_field_id IN (#{query_cfs.join(',')})
                                                      and i.id IN (#{ids.join(',')})
                                                    ORDER BY i.id, cv.custom_field_id, cv.id
                                                  ) cv
                                                  WHERE cv.row_number <= 3
                                                ) cv on cv.id = #{CustomValue.table_name}.id
                                          ").order(:customized_id, :custom_field_id, :id).select("#{CustomValue.table_name}.*, cv.cnt, cv.field_format")
                when :postgresql, :sqlserver
                  cvs = CustomValue.joins("INNER JOIN
                                                (
                                                  SELECT cv.id
                                                         cv.cnt,
                                                         cv.field_format
                                                  FROM
                                                  (
                                                    SELECT cv.id,
                                                           cv_m.cnt,
                                                           cf.field_format,
                                                           case when cf.multiple = #{Issue.connection.quoted_true} and cf.acl_trim_multiple = #{Issue.connection.quoted_true} then 1 else 0 end as mlt,
                                                           ROW_NUMBER() OVER (PARTITION BY i.id, cv.custom_field_id, ORDER BY i.id, cv.custom_field_id, cv.id) as row_number
                                                    FROM custom_values cv
                                                         INNER JOIN custom_fields cf on cf.id = cv.custom_field_id
                                                         INNER JOIN issues i on i.id = cv.customized_id
                                                         INNER JOIN (SELECT COUNT(1) as cnt, cv.custom_field_id, cv.customized_id FROM custom_values cv WHERE cv.customized_type = 'Issue' and cv.custom_field_id IN (#{query_cfs.join(',')}) and cv.customized_id IN (#{ids.join(',')}) GROUP BY cv.custom_field_id, cv.customized_id) cv_m on cv_m.custom_field_id = cf.id and cv_m.customized_id = i.id
                                                    WHERE cv.customized_type = 'Issue'
                                                      and cv.custom_field_id IN (#{query_cfs.join(',')})
                                                      and i.id IN (#{ids.join(',')})
                                                    ORDER BY i.id, cv.custom_field_id, cv.id
                                                  ) cv
                                                  WHERE cv.mlt = 0 OR cv.row_number <= 3
                                                ) cv on cv.id = #{CustomValue.table_name}.id
                                          ").order(:customized_id, :custom_field_id, :id).select("#{CustomValue.table_name}.*, cv.cnt, cv.field_format")
              end
              cvs = cvs.preload(:custom_field)
              u_ids = []
              cvs = cvs.inject({}) { |h, it|
                h[it.customized_id] ||= []
                h[it.customized_id] << it
                u_ids << it.value.to_i if it.attributes['field_format'] == 'user'
                h
              }
              # TODO: move load users to FieldFormat and propagate for all childs of RecordList
              if u_ids.present?
                u_ids = User.where(id: u_ids).group_by(&:id)
              end
              issues.each do |issue|
                issue.acl_cf_casted_values = {}
                if (cv = cvs[issue.id]).present?
                  cv = cv.group_by(&:custom_field_id)
                  cv.each do |(cf_id, values)|
                    cfv = issue.custom_field_values.find { |cfv| cfv.custom_field_id == cf_id }
                    next if cfv.blank?

                    if values.first.custom_field.field_format  == 'user'
                      issue.acl_cf_casted_values[cf_id] = values.map { |v| u_ids[v.value.to_i].try(:first) }
                    end

                    cfv.acl_trimmed_size = values.first.attributes['cnt'].to_i
                    cfv.send :value=, values, '=', true
                  end
                end
              end
            end
          else
            if has_custom_field_column?
              scope = scope.preload(:custom_values)
            end
            issues = scope.to_a
        end

        if has_column?(:spent_hours)
          Issue.load_visible_spent_hours(issues)
        end
        if has_column?(:total_spent_hours)
          Issue.load_visible_total_spent_hours(issues)
        end
        if has_column?(:last_updated_by)
          Issue.load_visible_last_updated_by(issues)
        end
        if has_column?(:relations)
          Issue.load_visible_relations(issues)
        end
        if has_column?(:last_notes)
          Issue.load_visible_last_notes(issues)
        end
        issues
      rescue ::ActiveRecord::StatementInvalid => e
        raise Query::StatementInvalid.new(e.message)
      end
    end
  end
end