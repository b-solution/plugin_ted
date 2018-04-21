module Acl::Patches::Controllers
  module IssuesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        skip_before_action :authorize, only: [:acl_cf_trimmed_all]
      end
    end

    module InstanceMethods
      def acl_cf_trimmed_all
        return if find_issue == false
        unless @issue.visible?
          render_403
          return
        end
        @cf = @issue.visible_custom_field_values.find { |cf| cf.custom_field_id == params[:cf_id].to_i }
        if @cf.blank?
          render_404
          return
        end

        render layout: false
      end
    end
  end
end