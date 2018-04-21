module Acl::Patches::Models
  module ProjectPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :notified_users, :acl
      end
    end

    module InstanceMethods
      def notified_users_with_acl
        @notified_users ||= User.active.joins(members: :project).where("#{Project.table_name}.id = ? and (#{Member.table_name}.mail_notification = ? or #{User.table_name}.mail_notification = 'all')", self.id, true)
      end
    end
  end
end