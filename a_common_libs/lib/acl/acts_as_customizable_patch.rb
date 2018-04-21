module Acl
  module ActsAsCustomizablePatch
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        class << self
          alias_method_chain :acts_as_customizable, :acl
        end
      end
    end

    module ClassMethods
      def acts_as_customizable_with_acl(options={})
        acts_as_customizable_without_acl(options)
        return if self.included_modules.include?(Acl::ActsAsCustomizablePatch::AclInstanceMethods)
        send :include, Acl::ActsAsCustomizablePatch::AclInstanceMethods
      end
    end

    module AclInstanceMethods
      def self.included(base)
        base.send :alias_method_chain, :custom_field_values=, :acl
        base.send :alias_method_chain, :custom_field_values, :acl
        base.send :alias_method_chain, :save_custom_field_values, :acl
        base.class_eval do
          attr_accessor :acl_cfv_hash
        end
      end

      def custom_field_values_with_acl
        Rails.logger.debug "\n ----------------------------- WARNING: a_common_libs - custom_field_values OVERWRITTEN COMPLETELY (Acl::Patches::Redmine::Acts::Customizable::InstanceMethodsPatch)"
        @acl_cfv_hash ||= {}
        @custom_field_values ||= available_custom_fields.collect do |field|
          x = CustomFieldValue.new
          x.custom_field = field
          x.customized = self
          @acl_cfv_hash[field.id.to_s] = x
          x
        end
      end

      def custom_field_values_with_acl=(values, action='=')
        if action == '='
          send :custom_field_values_without_acl=, values
        else
          self.custom_field_values
          values.stringify_keys.each do |(key, value)|
            if @acl_cfv_hash.has_key?(key)
              @acl_cfv_hash[key].send :value=, value, action
            end
          end
        end

        @custom_field_values_changed = true
      end

      def custom_field_values_append=(values)
        send :custom_field_values=, values, '+'
      end

      def custom_field_values_delete=(values)
        send :custom_field_values=, values, '-'
      end

      def save_custom_field_values_with_acl
        Rails.logger.debug "\n ----------------------------- WARNING: a_common_libs - save_custom_field_values OVERWRITTEN COMPLETELY (Acl::Patches::Redmine::Acts::Customizable::InstanceMethodsPatch)"
        custom_field_values.each do |custom_field_value|
          next unless custom_field_value.acl_changed

          skip_full_update = false
          if custom_field_value.acl_append.present?
            custom_field_value.acl_append.each do |v|
              v = CustomValue.where(customized: self, custom_field: custom_field_value.custom_field, value: v).first_or_initialize({})
              v.save
            end
            skip_full_update = true
          end

          if custom_field_value.acl_delete.present?
            CustomValue.where(customized: self, custom_field_id: custom_field_value.custom_field.id)
                       .where(value: custom_field_value.acl_delete)
                       .delete_all
            skip_full_update = true
          end

          next if skip_full_update

          to_keep = []
          if custom_field_value.value.is_a?(Array)
            custom_field_value.value.each do |v|
              if custom_field_value.acl_value.present? && custom_field_value.acl_value[v].present?
                to_keep << custom_field_value.acl_value[v]
              else
                v = CustomValue.new(customized: self, custom_field: custom_field_value.custom_field, value: v)
                v.save
                to_keep << v.id
              end
            end

            CustomValue.where(customized: self, custom_field_id: custom_field_value.custom_field.id)
                       .where('id not in (?)', to_keep + [0])
                       .delete_all
          else
            target = custom_values.detect { |cv| cv.custom_field == custom_field_value.custom_field }
            target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field)
            target.value = custom_field_value.value
            target.save
          end
        end
        self.custom_values.reload
        @custom_field_values_changed = false
        true
      end
    end
  end
end