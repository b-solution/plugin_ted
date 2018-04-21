module Acl::Patches::Models
  module CustomFieldPatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'ajaxable', 'acl_trim_multiple'
      end
    end
  end
end