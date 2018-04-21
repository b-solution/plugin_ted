module Acl::Patches::Models
  module IssuePatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend(ClassMethods)

      base.class_eval do
        attr_accessor :acl_cf_casted_values
        class << self
          alias_method_chain :allowed_target_projects, :acl
        end

        alias_method_chain :safe_attributes=, :acl

        safe_attributes 'custom_field_values_append',
                        'custom_field_values_delete',
                        if: lambda { |issue, user| issue.new_record? || issue.attributes_editable?(user) }
      end
    end

    module ClassMethods
      def allowed_target_projects_with_acl(user=User.current, current_project=nil)
        sc = allowed_target_projects_without_acl(user, current_project)
        fp = user.favourite_project
        if fp.present?
          sc.order("case when #{Project.table_name}.id = #{fp.id} then 0 else 1 end")
        else
          sc
        end
      end
    end

    module InstanceMethods
      def safe_attributes_with_acl=(attrs, user=User.current)
        if attrs.present?
          editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
          if attrs['custom_field_values_append'].present?
            attrs['custom_field_values_append'].select! { |k, v| editable_custom_field_ids.include?(k.to_s) }
          end

          if attrs['custom_field_values_delete'].present?
            attrs['custom_field_values_delete'].select! { |k, v| editable_custom_field_ids.include?(k.to_s) }
          end

          if (attrs.keys.map(&:to_s) - %w(custom_field_values_append custom_field_values_delete lock_version notes private_notes)).size == 0
            attrs.delete('lock_version')
          end
        end

        send :safe_attributes_without_acl=, attrs, user
      end
    end
  end
end